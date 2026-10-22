#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab stays broken for the student.
# Taken from solution.md - if one changes, change the other.
set -eu

NAMESPACE="flows-demo"

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

kcadm update realms/inventory -s 'passwordPolicy=length(12) and digits(1)'
FLOW=browser-stock-admin-otp
if ! kcadm get authentication/flows -r inventory --fields alias --format csv --noquotes | tr -d '\r' | grep -qx "$FLOW"; then
  kcadm create authentication/flows/browser/copy -r inventory -s newName="$FLOW"
fi
EXECS="$(kcadm get "authentication/flows/$FLOW/executions" -r inventory)"
# The conditional subflow is the one subflow whose requirement is CONDITIONAL.
SUBFLOW="$(printf '%s' "$EXECS" | in_tester_jq -r '[.[] | select(.authenticationFlow == true and .requirement == "CONDITIONAL")][0].displayName')"
SUBFLOW_PATH="$(printf '%s' "$SUBFLOW" | sed 's/ /%20/g')"
# Remove "Condition - user configured", so the role alone decides.
for EXEC_ID in $(printf '%s' "$EXECS" | in_tester_jq -r '.[] | select(.providerId == "conditional-user-configured") | .id'); do
  kcadm delete "authentication/executions/$EXEC_ID" -r inventory
done
if ! printf '%s' "$EXECS" | grep -q '"conditional-user-role"'; then
  kcadm create "authentication/flows/$SUBFLOW_PATH/executions/execution" -r inventory -s provider=conditional-user-role
fi
EXECS="$(kcadm get "authentication/flows/$FLOW/executions" -r inventory)"
ROLE_EXEC_ID="$(printf '%s' "$EXECS" | in_tester_jq -r '[.[] | select(.providerId == "conditional-user-role")][0].id')"
printf '%s' "$EXECS" | in_tester_jq -c '[.[] | select(.providerId == "conditional-user-role")][0] | .requirement = "REQUIRED"' \
  | kcadm update "authentication/flows/$FLOW/executions" -r inventory -f -
printf '%s' "$EXECS" | in_tester_jq -c '[.[] | select(.providerId == "auth-otp-form")][0] | .requirement = "REQUIRED"' \
  | kcadm update "authentication/flows/$FLOW/executions" -r inventory -f -
if ! printf '%s' "$EXECS" | in_tester_jq -e '[.[] | select(.providerId == "conditional-user-role")][0].authenticationConfig' >/dev/null; then
  kcadm create "authentication/executions/$ROLE_EXEC_ID/config" -r inventory \
    -s alias=stock-admin-only -s 'config.condUserRole=stock-admin' -s 'config.negate=false'
fi
kcadm update realms/inventory -s browserFlow="$FLOW"
