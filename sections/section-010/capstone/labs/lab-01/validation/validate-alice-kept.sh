#!/usr/bin/env bash
# PASS when alice is the same user, still in warehouse, and still gets a token.
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

NAMESPACE="userscapstone-demo"
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
password_token() {
  # password_token REALM CLIENT USERNAME PASSWORD: prints the access token, or
  # "NO_TOKEN" followed by the error the token endpoint returned.
  kubectl -n "$NAMESPACE" exec deploy/tester -- sh -c '
    RESPONSE=$(curl -s "http://keycloak:8080/realms/$1/protocol/openid-connect/token" \
      -d grant_type=password -d client_id="$2" -d username="$3" -d password="$4")
    TOKEN=$(printf "%s" "$RESPONSE" | jq -r ".access_token // empty")
    if [ -n "$TOKEN" ]; then printf "%s" "$TOKEN"; else
      printf "NO_TOKEN %s" "$(printf "%s" "$RESPONSE" | jq -c "{error, error_description}" 2>/dev/null)"; fi
  ' sh "$1" "$2" "$3" "$4" 2>/dev/null
}
token_claims() {
  # token_claims TOKEN: prints the payload of a JWT as JSON (decoded in tester).
  printf '%s' "$1" | kubectl -n "$NAMESPACE" exec -i deploy/tester -- \
    jq -R 'split(".")[1] | gsub("-";"+") | gsub("_";"/") | . + ("=" * ((4 - length % 4) % 4)) | @base64d | fromjson'
}

EXPECTED="$(kubectl -n "$NAMESPACE" get configmap capstone-baseline -o jsonpath='{.data.alice}')"
ALICE_ID="$(user_id inventory alice)"
if [ "$ALICE_ID" != "$EXPECTED" ]; then
  echo "FAIL: alice is missing or was created again."; exit 1
fi
if ! kcadm get "users/$ALICE_ID/groups" -r inventory --fields name | flat | grep -q '"name":"warehouse"'; then
  echo "FAIL: alice is no longer a member of the group warehouse."; exit 1
fi
TOKEN="$(password_token inventory inventory-cli alice alice-password)"
case "$TOKEN" in
  "") echo "FAIL: could not run curl in the tester pod."; exit 1 ;;
  NO_TOKEN*) echo "FAIL: alice gets no token from the realm inventory: ${TOKEN#NO_TOKEN }"; exit 1 ;;
esac
USERNAME="$(token_claims "$TOKEN" | kubectl -n "$NAMESPACE" exec -i deploy/tester -- jq -r .preferred_username)"
if [ "$USERNAME" != "alice" ]; then
  echo "FAIL: the token's preferred_username is '$USERNAME', expected 'alice'."
  exit 1
fi
echo "PASS: alice is unchanged."
exit 0
