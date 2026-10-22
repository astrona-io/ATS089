#!/usr/bin/env bash
# PASS when alice and bob still get tokens through the direct grant flow.
set -uo pipefail

NAMESPACE="flowscapstone-demo"
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
TOKEN="$(password_token inventory inventory-cli bob bob-password)"
case "$TOKEN" in
  "") echo "FAIL: could not run curl in the tester pod."; exit 1 ;;
  NO_TOKEN*) echo "FAIL: bob gets no token from the realm inventory: ${TOKEN#NO_TOKEN }"; exit 1 ;;
esac
USERNAME="$(token_claims "$TOKEN" | kubectl -n "$NAMESPACE" exec -i deploy/tester -- jq -r .preferred_username)"
if [ "$USERNAME" != "bob" ]; then
  echo "FAIL: the token's preferred_username is '$USERNAME', expected 'bob'."
  exit 1
fi
echo "PASS: alice and bob still get tokens."
exit 0
