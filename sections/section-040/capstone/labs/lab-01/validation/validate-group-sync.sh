#!/usr/bin/env bash
# PASS when the group warehouse exists in Keycloak, ldap-ana is a member and ldap-ben is not.
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

flat() { tr -d ' \n\r\t'; }
ANA_GROUPS="$(kcadm get "users/$(user_id inventory ldap-ana)/groups" -r inventory --fields name 2>/dev/null | flat)"
BEN_GROUPS="$(kcadm get "users/$(user_id inventory ldap-ben)/groups" -r inventory --fields name 2>/dev/null | flat)"
if ! printf '%s' "$ANA_GROUPS" | grep -q '"name":"warehouse"'; then
  echo "FAIL: ldap-ana is not a member of warehouse in Keycloak. Groups: $ANA_GROUPS"; exit 1
fi
if printf '%s' "$BEN_GROUPS" | grep -q '"name":"warehouse"'; then
  echo "FAIL: ldap-ben is a member of warehouse, but LDAP says he is not."; exit 1
fi
echo "PASS: the LDAP group warehouse reached Keycloak with the right member."
exit 0
