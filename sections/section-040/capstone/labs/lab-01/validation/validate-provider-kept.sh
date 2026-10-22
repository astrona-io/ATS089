#!/usr/bin/env bash
# PASS when openldap has its original ID, READ_ONLY edit mode and the users DN ou=people,dc=example,dc=org.
set -uo pipefail

NAMESPACE="federationcapstone-demo"
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
  | in_tester_jq -c '.[0] // empty | {id, editMode: .config.editMode[0], usersDn: .config.usersDn[0]}')"
if [ -z "$PROVIDER" ]; then echo "FAIL: the provider openldap is gone."; exit 1; fi
EXPECTED_ID="$(kubectl -n "$NAMESPACE" get configmap capstone-baseline -o jsonpath='{.data.provider}')"
for expected in "\"id\":\"$EXPECTED_ID\"" '"editMode":"READ_ONLY"' '"usersDn":"ou=people,dc=example,dc=org"'; do
  if ! printf '%s' "$PROVIDER" | grep -q "$expected"; then
    echo "FAIL: openldap does not have $expected. Settings: $PROVIDER"; exit 1
  fi
done
echo "PASS: the original provider is repaired and still read-only."
exit 0
