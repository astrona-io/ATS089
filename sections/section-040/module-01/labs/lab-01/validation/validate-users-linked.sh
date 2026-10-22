#!/usr/bin/env bash
# PASS when ldap-ana and ldap-ben exist in Keycloak with federationLink set to the openldap provider.
set -uo pipefail

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

PROVIDER_ID="$(kcadm get components -r inventory -q name=openldap -q type=org.keycloak.storage.UserStorageProvider --fields id --format csv --noquotes | tr -d '\r' | head -1)"
for user in ldap-ana ldap-ben; do
  USER_ID="$(user_id inventory "$user")"
  if [ -z "$USER_ID" ]; then
    echo "FAIL: $user is not in Keycloak. Synchronize the users from LDAP."; exit 1
  fi
  LINK="$(kcadm get "users/$USER_ID" -r inventory --fields federationLink --format csv --noquotes | tr -d '\r')"
  if [ "$LINK" != "$PROVIDER_ID" ]; then
    echo "FAIL: $user is not linked to the provider openldap."; exit 1
  fi
done
echo "PASS: ldap-ana and ldap-ben are linked to openldap."
exit 0
