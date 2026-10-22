#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab stays broken for the student.
# Taken from solution.md - if one changes, change the other.
set -eu

NAMESPACE="roles-demo"

kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin

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

kcadm get roles/warehouse-clerk -r inventory >/dev/null 2>&1 || \
  kcadm create roles -r inventory -s name=warehouse-clerk -s 'description=Warehouse staff: read and change stock'
kcadm add-roles -r inventory --rname warehouse-clerk --cclientid inventory-api \
  --rolename stock-read --rolename stock-write
[ -n "$(group_id inventory warehouse)" ] || kcadm create groups -r inventory -s name=warehouse
kcadm add-roles -r inventory --gname warehouse --rolename warehouse-clerk
add_to_group inventory alice warehouse
