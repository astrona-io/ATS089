#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab stays broken for the student.
# Taken from solution.md - if one changes, change the other.
set -eu

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

FLOW=browser-stock-admin-otp
EXECS="$(kcadm get "authentication/flows/$FLOW/executions" -r inventory)"
# The subflow that holds the OTP form is the one to switch back to CONDITIONAL.
printf '%s' "$EXECS" | in_tester_jq -c '
  . as $all
  | ([$all[] | select(.providerId == "auth-otp-form")][0].level - 1) as $parent_level
  | [$all[] | select(.authenticationFlow == true and .level == $parent_level and .requirement == "DISABLED")][0]
  | .requirement = "CONDITIONAL"' \
  | kcadm update "authentication/flows/$FLOW/executions" -r inventory -f -
kcadm update authentication/required-actions/CONFIGURE_TOTP -r inventory -s enabled=true
kcadm update authentication/required-actions/webauthn-register-passwordless -r inventory -s enabled=true
kcadm update realms/inventory -s webAuthnPolicyPasswordlessUserVerificationRequirement=required
