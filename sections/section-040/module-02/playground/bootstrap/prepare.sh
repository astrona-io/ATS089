#!/usr/bin/env bash
# OS prep for the "Sign Users In Through Another Identity Provider" playground (`ats-089-playground-040-02`).
#
# Environment preparation only. There is no task and no grading. This script:
#   1. applies the module's starting workloads (Keycloak 26.8.1 and tester),
#   2. waits until Keycloak answers and the administrator can sign in,
#   3. creates the realms inventory and partner, alice, pat, inventory-web and inventory-broker.
set -euo pipefail

NAMESPACE="broker-demo"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_DIR=""
for candidate in "$SCRIPT_DIR/../manifests" "./manifests" "$SCRIPT_DIR/manifests"; do
  [ -d "$candidate" ] && { MANIFEST_DIR="$candidate"; break; }
done

# lab-start.yaml is also listed under bootstrap.manifests in config.yaml, so it
# may already be applied. kubectl apply is idempotent.
if [ -n "$MANIFEST_DIR" ] && [ -f "$MANIFEST_DIR/lab-start.yaml" ]; then
  echo "[playground] Applying starting workloads..."
  kubectl apply -f "$MANIFEST_DIR/lab-start.yaml"
fi

# The first rollout pulls a large image and Keycloak takes a while to start.
echo "[playground] Waiting for Keycloak (this can take a few minutes)..."
kubectl -n "$NAMESPACE" rollout status deployment/keycloak --timeout=600s
kubectl -n "$NAMESPACE" rollout status deployment/tester --timeout=300s


kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}

# The bootstrap administrator can need a few seconds after /health/ready.
for _ in $(seq 1 30); do
  kcadm config credentials --server http://localhost:8080 --realm master \
    --user admin --password admin >/dev/null 2>&1 && break
  sleep 5
done
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
if [ -z "$(client_uuid partner inventory-broker)" ]; then
  kcadm create clients -r partner -s clientId=inventory-broker -s enabled=true \
    -s publicClient=false -s secret=inventory-broker-secret \
    -s standardFlowEnabled=true -s directAccessGrantsEnabled=false \
    -s 'redirectUris=["http://localhost:8080/realms/inventory/broker/partner/endpoint"]'
fi

echo "[playground] Ready."
kubectl -n "$NAMESPACE" get pods -o wide
echo "[playground] Keycloak answers at http://keycloak:8080 from the tester pod."
