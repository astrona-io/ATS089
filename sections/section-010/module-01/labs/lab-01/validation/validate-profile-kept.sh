#!/usr/bin/env bash
# PASS when the user profile still requires lastName and the VERIFY_PROFILE required action is enabled.
set -uo pipefail

NAMESPACE="users-demo"
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

REQUIRED="$(kcadm get users/profile -r inventory \
  | in_tester_jq -r '[.attributes[] | select(.name == "lastName") | (.required != null)][0]')"
if [ "$REQUIRED" != "true" ]; then
  echo "FAIL: the user profile no longer requires lastName. Complete dave's profile instead."
  exit 1
fi
ENABLED="$(kcadm get authentication/required-actions/VERIFY_PROFILE -r inventory --fields enabled --format csv --noquotes | tr -d '\r')"
if [ "$ENABLED" != "true" ]; then
  echo "FAIL: the required action VERIFY_PROFILE is disabled. Turn it back on."
  exit 1
fi
echo "PASS: the user profile and VERIFY_PROFILE are unchanged."
exit 0
