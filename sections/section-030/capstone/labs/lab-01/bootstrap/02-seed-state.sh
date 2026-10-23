#!/usr/bin/env bash
# Creates the starting state for ats-089-capstone-030.
#
# Builds browser-stock-admin-otp (OTP only for stock-admin) and binds it, then
# breaks the second factor in four places:
#   - the conditional OTP subflow is DISABLED,
#   - the required action CONFIGURE_TOTP is disabled,
#   - the required action webauthn-register-passwordless is disabled,
#   - the passwordless WebAuthn policy says user verification is discouraged.
#
# The repairs are NOT made here — they are the task.
set -euo pipefail
# grep -q stops reading at the first match; under pipefail the command
# writing into the pipe then fails with SIGPIPE and a match looks like a
# failure. This wrapper reads all input instead and keeps grep's exit status.
grep() {
  local arg quiet=0 args=()
  for arg in "$@"; do
    case "$arg" in
      --quiet|--silent) quiet=1 ;;
      --*) args+=("$arg") ;;
      -*q*) quiet=1; [ "$arg" = "-q" ] || args+=("${arg//q/}") ;;
      *) args+=("$arg") ;;
    esac
  done
  if [ "$quiet" = 1 ]; then command grep "${args[@]}" >/dev/null; else command grep "$@"; fi
}

NAMESPACE="flowscapstone-demo"

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

echo "[setup] Creating the realm role stock-admin and the user bob, who holds it..."
kcadm get roles/stock-admin -r inventory >/dev/null 2>&1 || kcadm create roles -r inventory -s name=stock-admin
create_user inventory bob bob-password Bob Example
kcadm add-roles -r inventory --uusername bob --rolename stock-admin

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

echo "[lab] Breaking the second factor..."
EXECS="$(kcadm get "authentication/flows/$FLOW/executions" -r inventory)"
printf '%s' "$EXECS" | in_tester_jq -c '[.[] | select(.authenticationFlow == true and .requirement == "CONDITIONAL")][0] | .requirement = "DISABLED"' \
  | kcadm update "authentication/flows/$FLOW/executions" -r inventory -f -
kcadm update authentication/required-actions/CONFIGURE_TOTP -r inventory -s enabled=false
if ! kcadm get authentication/required-actions/webauthn-register-passwordless -r inventory >/dev/null 2>&1; then
  kcadm create authentication/register-required-action -r inventory \
    -s providerId=webauthn-register-passwordless -s 'name=Webauthn Register Passwordless'
fi
kcadm update authentication/required-actions/webauthn-register-passwordless -r inventory -s enabled=false
kcadm update realms/inventory -s webAuthnPolicyPasswordlessUserVerificationRequirement=discouraged

kubectl -n "$NAMESPACE" create configmap capstone-baseline \
  --from-literal=flow="$(kcadm get authentication/flows -r inventory --fields id,alias --format csv --noquotes | tr -d '\r' | awk -F, -v flow="$FLOW" '$2 == flow {print $1}')" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "[lab] Starting state ready."
kubectl -n "$NAMESPACE" get pods
