#!/usr/bin/env bash
# Creates the starting state for ats-089-lab-010-01.
#
# Creates the realm inventory, alice and inventory-cli, then three users who
# cannot get tokens: bob has a temporary password (UPDATE_PASSWORD), carol is
# disabled, and dave has no last name although the user profile requires one.
#
# The fixes are NOT applied here — finding and applying them is the task.
set -euo pipefail

NAMESPACE="users-demo"

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

echo "[lab] Creating bob with a temporary password..."
create_user inventory bob bob-password Bob Example
kcadm set-password -r inventory --username bob --new-password bob-password --temporary

echo "[lab] Creating carol and disabling her account..."
create_user inventory carol carol-password Carol Example
kcadm update "users/$(user_id inventory carol)" -r inventory -s enabled=false

echo "[lab] Creating dave without a last name..."
# The user profile requires lastName for the role user only, so an
# administrator can create dave without one; dave then cannot finish signing in.
if [ -z "$(user_id inventory dave)" ]; then
  kcadm create users -r inventory -s username=dave -s enabled=true \
    -s email=dave@example.com -s emailVerified=true -s firstName=Dave
  kcadm set-password -r inventory --username dave --new-password dave-password
fi

# The grader compares the users' IDs with these, so deleting and recreating a
# user is caught.
kubectl -n "$NAMESPACE" create configmap lab-baseline \
  --from-literal=bob="$(user_id inventory bob)" \
  --from-literal=carol="$(user_id inventory carol)" \
  --from-literal=dave="$(user_id inventory dave)" \
  --dry-run=client -o yaml | kubectl apply -f -
echo "[lab] bob, carol and dave cannot get tokens. Finding out why is the task."

echo "[lab] Starting state ready."
kubectl -n "$NAMESPACE" get pods
