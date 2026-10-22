#!/usr/bin/env bash
# PASS when bob, carol and dave have the IDs the lab started with.
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

for user in bob carol dave; do
  EXPECTED="$(kubectl -n "$NAMESPACE" get configmap lab-baseline -o jsonpath="{.data.$user}")"
  ACTUAL="$(user_id inventory "$user")"
  if [ -z "$ACTUAL" ]; then
    echo "FAIL: the user $user does not exist."
    exit 1
  fi
  if [ "$EXPECTED" != "$ACTUAL" ]; then
    echo "FAIL: the user $user was deleted and created again. Fix the existing user instead."
    exit 1
  fi
done
echo "PASS: bob, carol and dave are the users the lab started with."
exit 0
