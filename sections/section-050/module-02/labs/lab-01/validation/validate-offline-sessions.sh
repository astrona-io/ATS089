#!/usr/bin/env bash
# Confirms bob has no offline session and alice still has one
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

NAMESPACE="sessions-demo"
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

token_lifespan() {
  # token_lifespan CLIENT_ID: prints exp minus iat, in seconds, of an access token for alice.
  kubectl -n "$NAMESPACE" exec deploy/tester -- curl -s \
    http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=password -d client_id="$1" -d username=alice -d password=alice-password \
    | in_tester_jq -r '.access_token' \
    | in_tester_jq -R 'split(".")[1] | gsub("-";"+") | gsub("_";"/") | . + ("=" * ((4 - length % 4) % 4)) | @base64d | fromjson | .exp - .iat'
}
offline_session_count() {
  # offline_session_count USERNAME: prints how many offline sessions the user has for inventory-cli.
  local uid cid
  uid="$(user_id inventory "$1")"; cid="$(client_uuid inventory inventory-cli)"
  kcadm get "users/$uid/offline-sessions/$cid" -r inventory | in_tester_jq 'length'
}
BOBN="$(offline_session_count bob)"
ALICEN="$(offline_session_count alice)"
if [ "$BOBN" != "0" ]; then echo "FAIL: bob still has $BOBN offline session(s) for inventory-cli."; exit 1; fi
if [ "${ALICEN:-0}" -lt 1 ]; then echo "FAIL: alice lost her offline session; only bob's may be revoked."; exit 1; fi
echo "PASS: bob's offline session is revoked and alice's is kept."
exit 0
