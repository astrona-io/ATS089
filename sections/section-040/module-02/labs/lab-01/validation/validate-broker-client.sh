#!/usr/bin/env bash
# PASS when partner has the confidential client inventory-broker with the standard flow, the inventory broker endpoint as redirect URI and the secret inventory-broker-secret.
set -uo pipefail

NAMESPACE="broker-demo"
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
CLIENT_ID="$(client_uuid partner inventory-broker)"
if [ -z "$CLIENT_ID" ]; then echo "FAIL: the realm partner has no client inventory-broker."; exit 1; fi
SETTINGS="$(kcadm get "clients/$CLIENT_ID" -r partner --fields publicClient,standardFlowEnabled,redirectUris | flat)"
for expected in '"publicClient":false' '"standardFlowEnabled":true' 'http://localhost:8080/realms/inventory/broker/partner/endpoint'; do
  if ! printf '%s' "$SETTINGS" | grep -q "$expected"; then
    echo "FAIL: inventory-broker does not have $expected. Settings: $SETTINGS"; exit 1
  fi
done
SECRET="$(kcadm get "clients/$CLIENT_ID/client-secret" -r partner --fields value --format csv --noquotes | tr -d '\r')"
if [ "$SECRET" != "inventory-broker-secret" ]; then
  echo "FAIL: the client secret of inventory-broker is not inventory-broker-secret."; exit 1
fi
echo "PASS: inventory-broker is set up in partner."
exit 0
