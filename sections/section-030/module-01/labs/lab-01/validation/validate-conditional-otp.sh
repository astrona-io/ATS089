#!/usr/bin/env bash
# PASS when browser-stock-admin-otp has a role condition for stock-admin, an active OTP form, and is bound as the browser flow.
set -uo pipefail

NAMESPACE="flows-demo"
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
FLOW=browser-stock-admin-otp
EXECS="$(kcadm get "authentication/flows/$FLOW/executions" -r inventory 2>/dev/null)"
if [ -z "$EXECS" ]; then echo "FAIL: the flow $FLOW does not exist."; exit 1; fi
if [ "$(printf '%s' "$EXECS" | in_tester_jq -r '[.[] | select(.authenticationFlow == true and .requirement == "CONDITIONAL")] | length')" -lt 1 ]; then
  echo "FAIL: $FLOW has no subflow with the requirement CONDITIONAL."; exit 1
fi
if [ "$(printf '%s' "$EXECS" | in_tester_jq -r '[.[] | select(.providerId == "conditional-user-configured" and .requirement != "DISABLED")] | length')" != "0" ]; then
  echo "FAIL: Condition - user configured is still active in $FLOW, so stock-admin users without OTP are never asked."; exit 1
fi
ROLE_EXEC="$(printf '%s' "$EXECS" | in_tester_jq -c '[.[] | select(.providerId == "conditional-user-role")][0] // empty')"
if [ -z "$ROLE_EXEC" ]; then echo "FAIL: $FLOW has no Condition - user role execution."; exit 1; fi
if [ "$(printf '%s' "$ROLE_EXEC" | in_tester_jq -r .requirement)" != "REQUIRED" ]; then
  echo "FAIL: Condition - user role is not REQUIRED."; exit 1
fi
CONFIG_ID="$(printf '%s' "$ROLE_EXEC" | in_tester_jq -r '.authenticationConfig // empty')"
if [ -z "$CONFIG_ID" ]; then echo "FAIL: Condition - user role has no configuration."; exit 1; fi
ROLE="$(kcadm get "authentication/config/$CONFIG_ID" -r inventory | in_tester_jq -r '.config.condUserRole // empty')"
if [ "$ROLE" != "stock-admin" ]; then
  echo "FAIL: Condition - user role checks '$ROLE', expected 'stock-admin'."; exit 1
fi
if [ "$(printf '%s' "$EXECS" | in_tester_jq -r '[.[] | select(.providerId == "auth-otp-form" and .requirement != "DISABLED")] | length')" -lt 1 ]; then
  echo "FAIL: the OTP Form in $FLOW is missing or DISABLED."; exit 1
fi
BINDINGS="$(kcadm get realms/inventory --fields browserFlow,directGrantFlow | flat)"
if ! printf '%s' "$BINDINGS" | grep -q "\"browserFlow\":\"$FLOW\""; then
  echo "FAIL: $FLOW is not the realm's browser flow. Bindings: $BINDINGS"; exit 1
fi
if ! printf '%s' "$BINDINGS" | grep -q '"directGrantFlow":"direct grant"'; then
  echo "FAIL: the direct grant flow binding changed. Bindings: $BINDINGS"; exit 1
fi
echo "PASS: browser-stock-admin-otp asks for OTP only for stock-admin and is bound as the browser flow."
exit 0
