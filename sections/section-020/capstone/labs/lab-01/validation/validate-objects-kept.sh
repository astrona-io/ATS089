#!/usr/bin/env bash
# PASS when warehouse, auditors and warehouse-clerk have their original IDs and alice and bob have no direct role mappings for these roles.
set -uo pipefail

NAMESPACE="rolescapstone-demo"
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
group_id() {
  # group_id REALM NAME: prints the ID of the top-level group NAME, or nothing.
  kcadm get groups -r "$1" -q search="$2" --fields id,name --format csv --noquotes \
    | tr -d '\r' | awk -F, -v name="$2" '$2 == name {print $1; exit}'
}
add_to_group() {
  # add_to_group REALM USERNAME GROUP
  local uid gid
  uid="$(user_id "$1" "$2")"; gid="$(group_id "$1" "$3")"
  kcadm update "users/$uid/groups/$gid" -r "$1" -s realm="$1" -s userId="$uid" -s groupId="$gid" -n
}

baseline() { kubectl -n "$NAMESPACE" get configmap capstone-baseline -o jsonpath="{.data.$1}"; }
for group in warehouse auditors; do
  if [ "$(group_id inventory "$group")" != "$(baseline "$group")" ]; then
    echo "FAIL: the group $group is missing or was created again."; exit 1
  fi
done
ROLE_ID="$(kcadm get roles/warehouse-clerk -r inventory --fields id --format csv --noquotes 2>/dev/null | tr -d '\r')"
if [ "$ROLE_ID" != "$(kubectl -n "$NAMESPACE" get configmap capstone-baseline -o jsonpath='{.data.warehouse-clerk}')" ]; then
  echo "FAIL: the role warehouse-clerk is missing or was created again."; exit 1
fi
API_ID="$(client_uuid inventory inventory-api)"
for user in alice bob; do
  USER_ID="$(user_id inventory "$user")"
  if kcadm get "users/$USER_ID/role-mappings/clients/$API_ID" -r inventory --fields name | flat | grep -q 'stock-'; then
    echo "FAIL: an inventory-api role is mapped to $user directly. Fix the groups instead."; exit 1
  fi
  if kcadm get "users/$USER_ID/role-mappings/realm" -r inventory --fields name | flat | grep -q '"name":"warehouse-clerk"'; then
    echo "FAIL: warehouse-clerk is mapped to $user directly."; exit 1
  fi
done
echo "PASS: the original groups and role were repaired, not replaced."
exit 0
