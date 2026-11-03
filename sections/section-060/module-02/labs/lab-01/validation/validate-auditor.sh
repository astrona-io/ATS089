#!/usr/bin/env bash
# Confirms auditor reads events and users and cannot create users
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

NAMESPACE="admin-delegation-demo"
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
if ! kcadm config credentials --server http://localhost:8080 --realm master \
     --user admin --password admin >/dev/null 2>&1; then
  echo "FAIL: could not sign in to Keycloak as the administrator."
  exit 1
fi

admin_token() {
  # admin_token USER: prints an access token for USER from the admin-cli client of inventory.
  kubectl -n "$NAMESPACE" exec deploy/tester -- curl -s \
    http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=password -d client_id=admin-cli -d username="$1" -d password="$1-password" \
    | in_tester_jq -r '.access_token // empty'
}
api_status() {
  # api_status USER METHOD PATH [BODY]: prints the HTTP status of an Admin API call made as USER.
  local token
  token="$(admin_token "$1")"
  kubectl -n "$NAMESPACE" exec deploy/tester -- curl -s -o /dev/null -w '%{http_code}' \
    -X "$2" "http://keycloak:8080/admin/realms/inventory/$3" \
    -H "Authorization: Bearer $token" -H 'Content-Type: application/json' ${4:+-d "$4"}
}
A="$(api_status auditor GET events)"
B="$(api_status auditor GET users)"
C="$(api_status auditor POST users '{}')"
if [ "$A" != "200" ]; then echo "FAIL: auditor got $A when reading events, not 200."; exit 1; fi
if [ "$B" != "200" ]; then echo "FAIL: auditor got $B when listing users, not 200."; exit 1; fi
if [ "$C" != "403" ]; then echo "FAIL: auditor got $C when creating users, not 403."; exit 1; fi
echo "PASS: auditor reads events and users and cannot create users."
exit 0
