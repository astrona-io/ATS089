#!/usr/bin/env bash
# PASS when inventory has an enabled oidc identity provider partner with the partner issuer, endpoints, client ID and the first broker login flow.
set -uo pipefail
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

IDP="$(kcadm get identity-provider/instances/partner -r inventory 2>/dev/null \
  | in_tester_jq -c '{providerId, enabled, flow: .firstBrokerLoginFlowAlias, issuer: .config.issuer, auth: .config.authorizationUrl, token: .config.tokenUrl, clientId: .config.clientId}')"
if [ -z "$IDP" ]; then echo "FAIL: the realm inventory has no identity provider with the alias partner."; exit 1; fi
for expected in '"providerId":"oidc"' '"enabled":true' '"flow":"first broker login"' \
    '"issuer":"http://localhost:8080/realms/partner"' \
    '"auth":"http://localhost:8080/realms/partner/protocol/openid-connect/auth"' \
    '"token":"http://localhost:8080/realms/partner/protocol/openid-connect/token"' \
    '"clientId":"inventory-broker"'; do
  if ! printf '%s' "$IDP" | grep -q "$expected"; then
    echo "FAIL: the identity provider partner does not have $expected. Settings: $IDP"; exit 1
  fi
done
echo "PASS: partner is an OpenID Connect identity provider of inventory."
exit 0
