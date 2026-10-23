#!/usr/bin/env bash
# PASS when the realm has an LDAP provider named openldap in READ_ONLY mode for ldap://openldap:389 and ou=people,dc=example,dc=org.
set -uo pipefail
# grep -q stops reading at the first match; under pipefail the command
# writing into the pipe then fails with SIGPIPE and a match looks like a
# failure. This wrapper reads all input instead and keeps grep's exit status.
grep() {
  local arg quiet=0 args=()
  for arg in "$@"; do
    case "$arg" in
      --quiet|--silent) quiet=1 ;;
      --*) args+=("$arg") ;;
      -*q*) quiet=1; [ "$arg" = "-q" ] || args+=("${arg//q/}") ;;
      *) args+=("$arg") ;;
    esac
  done
  if [ "$quiet" = 1 ]; then command grep "${args[@]}" >/dev/null; else command grep "$@"; fi
}

NAMESPACE="ldap-demo"
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
if ! kcadm config credentials --server http://localhost:8080 --realm master \
     --user admin --password admin >/dev/null 2>&1; then
  echo "FAIL: could not sign in to Keycloak as the administrator."
  exit 1
fi
user_id() {
  # user_id REALM USERNAME: prints the user's ID, or nothing.
  kcadm get users -r "$1" -q username="$2" -q exact=true --fields id --format csv --noquotes | tr -d '\r'
}
client_uuid() {
  # client_uuid REALM CLIENT_ID: prints the client's internal ID, or nothing.
  kcadm get clients -r "$1" -q clientId="$2" --fields id --format csv --noquotes | tr -d '\r'
}
create_user() {
  # create_user REALM USERNAME PASSWORD FIRST_NAME LAST_NAME
  if [ -z "$(user_id "$1" "$2")" ]; then
    kcadm create users -r "$1" -s username="$2" -s enabled=true \
      -s email="$2@example.com" -s emailVerified=true \
      -s firstName="$4" -s lastName="$5"
    kcadm set-password -r "$1" --username "$2" --new-password "$3"
  fi
}
in_tester_jq() {
  # in_tester_jq FILTER: runs jq in the tester pod on standard input.
  kubectl -n "$NAMESPACE" exec -i deploy/tester -- jq "$@"
}

PROVIDER="$(kcadm get components -r inventory -q name=openldap -q type=org.keycloak.storage.UserStorageProvider 2>/dev/null \
  | in_tester_jq -c '.[0] // empty | {providerId, editMode: .config.editMode[0], url: .config.connectionUrl[0], usersDn: .config.usersDn[0], importEnabled: .config.importEnabled[0]}')"
if [ -z "$PROVIDER" ]; then echo "FAIL: the realm has no user federation provider named openldap."; exit 1; fi
for expected in '"providerId":"ldap"' '"editMode":"READ_ONLY"' '"url":"ldap://openldap:389"' '"usersDn":"ou=people,dc=example,dc=org"' '"importEnabled":"true"'; do
  if ! printf '%s' "$PROVIDER" | grep -q "$expected"; then
    echo "FAIL: the provider openldap does not have $expected. Settings: $PROVIDER"; exit 1
  fi
done
echo "PASS: openldap is a read-only LDAP provider for ou=people."
exit 0
