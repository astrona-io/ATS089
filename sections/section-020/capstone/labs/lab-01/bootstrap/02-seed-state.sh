#!/usr/bin/env bash
# Creates the starting state for ats-089-capstone-020.
#
# Creates the role model of the realm inventory with three faults:
#   - the composite role warehouse-clerk has stock-read but not stock-write,
#   - the group auditors maps stock-write instead of stock-read,
#   - inventory-cli lost the default client scope roles, so no roles reach its tokens.
#
# The repairs are NOT made here — they are the task.
set -euo pipefail

NAMESPACE="rolescapstone-demo"

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

echo "[setup] Creating the inventory realm, the user alice and inventory-cli..."
kcadm get realms/inventory >/dev/null 2>&1 || kcadm create realms -s realm=inventory -s enabled=true
create_user inventory alice alice-password Alice Example
if [ -z "$(client_uuid inventory inventory-cli)" ]; then
  kcadm create clients -r inventory -s clientId=inventory-cli -s enabled=true \
    -s publicClient=true -s standardFlowEnabled=false -s directAccessGrantsEnabled=true
fi

echo "[setup] Creating the client inventory-api with the client roles stock-read and stock-write..."
if [ -z "$(client_uuid inventory inventory-api)" ]; then
  kcadm create clients -r inventory -s clientId=inventory-api -s enabled=true \
    -s publicClient=false -s standardFlowEnabled=false \
    -s directAccessGrantsEnabled=false -s serviceAccountsEnabled=false
fi
API_ID="$(client_uuid inventory inventory-api)"
for role in stock-read stock-write; do
  kcadm get "clients/$API_ID/roles/$role" -r inventory >/dev/null 2>&1 || \
    kcadm create "clients/$API_ID/roles" -r inventory -s name="$role"
done
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

create_user inventory bob bob-password Bob Example
kcadm get roles/warehouse-clerk -r inventory >/dev/null 2>&1 || kcadm create roles -r inventory -s name=warehouse-clerk
kcadm add-roles -r inventory --rname warehouse-clerk --cclientid inventory-api --rolename stock-read
[ -n "$(group_id inventory warehouse)" ] || kcadm create groups -r inventory -s name=warehouse
kcadm add-roles -r inventory --gname warehouse --rolename warehouse-clerk
add_to_group inventory alice warehouse
[ -n "$(group_id inventory auditors)" ] || kcadm create groups -r inventory -s name=auditors
kcadm add-roles -r inventory --gname auditors --cclientid inventory-api --rolename stock-write
add_to_group inventory bob auditors

echo "[lab] Removing the client scope roles from inventory-cli..."
CLI_ID="$(client_uuid inventory inventory-cli)"
ROLES_SCOPE_ID="$(kcadm get client-scopes -r inventory --fields id,name --format csv --noquotes | tr -d '\r' | awk -F, '$2 == "roles" {print $1}')"
kcadm delete "clients/$CLI_ID/default-client-scopes/$ROLES_SCOPE_ID" -r inventory || true

kubectl -n "$NAMESPACE" create configmap capstone-baseline \
  --from-literal=warehouse="$(group_id inventory warehouse)" \
  --from-literal=auditors="$(group_id inventory auditors)" \
  --from-literal=warehouse-clerk="$(kcadm get roles/warehouse-clerk -r inventory --fields id --format csv --noquotes | tr -d '\r')" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "[lab] Starting state ready."
kubectl -n "$NAMESPACE" get pods
