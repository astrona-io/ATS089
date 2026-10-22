#!/usr/bin/env bash
# Creates the starting state for ats-089-lab-040-02.
#
# Creates the realms inventory and partner, alice, pat, the client
# inventory-web and the realm role partner-user in inventory.
#
# The broker client, the identity provider and its mapper are NOT created
# here — creating them is the task.
set -euo pipefail

NAMESPACE="broker-demo"

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

echo "[setup] Creating the realm partner and its user pat..."
kcadm get realms/partner >/dev/null 2>&1 || kcadm create realms -s realm=partner -s enabled=true
create_user partner pat pat-password Pat Partner
echo "[setup] Creating the client inventory-web for browser sign-ins..."
if [ -z "$(client_uuid inventory inventory-web)" ]; then
  kcadm create clients -r inventory -s clientId=inventory-web -s enabled=true \
    -s publicClient=false -s secret=inventory-web-secret \
    -s standardFlowEnabled=true -s directAccessGrantsEnabled=false \
    -s 'redirectUris=["http://localhost:8080/*","http://keycloak:8080/*"]'
fi
kcadm get roles/partner-user -r inventory >/dev/null 2>&1 || kcadm create roles -r inventory -s name=partner-user

echo "[lab] Starting state ready."
kubectl -n "$NAMESPACE" get pods
