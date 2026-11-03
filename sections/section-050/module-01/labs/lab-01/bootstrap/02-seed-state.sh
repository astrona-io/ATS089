#!/usr/bin/env bash
# Creates the starting state for ats-089-lab-050-01.
# The objects and settings the task asks for are NOT created here.
set -euo pipefail

NAMESPACE="realm-settings-demo"

kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
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
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin

echo "[setup] Creating the realm inventory, the user alice and the client inventory-web..."
kcadm get realms/inventory >/dev/null 2>&1 || kcadm create realms -s realm=inventory -s enabled=true
create_user inventory alice alice-password Alice Example
if [ -z "$(client_uuid inventory inventory-web)" ]; then
  kcadm create clients -r inventory -s clientId=inventory-web -s enabled=true \
    -s publicClient=false -s secret=inventory-web-secret \
    -s standardFlowEnabled=true -s directAccessGrantsEnabled=false \
    -s 'redirectUris=["http://localhost:8080/*","http://keycloak:8080/*"]'
fi

echo "[lab] Starting state ready."
kubectl -n "$NAMESPACE" get pods
