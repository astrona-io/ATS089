#!/usr/bin/env bash
# PASS when erin and frank exist, are enabled, have the given names and email, a password, UPDATE_PASSWORD pending, and the group warehouse.
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
check_user() {
  # check_user USERNAME FIRST LAST
  local id state
  id="$(user_id inventory "$1")"
  if [ -z "$id" ]; then echo "FAIL: the user $1 does not exist."; exit 1; fi
  state="$(kcadm get "users/$id" -r inventory --fields enabled,email,firstName,lastName,requiredActions | flat)"
  for expected in '"enabled":true' "\"email\":\"$1@example.com\"" "\"firstName\":\"$2\"" "\"lastName\":\"$3\""; do
    if ! printf '%s' "$state" | grep -q "$expected"; then
      echo "FAIL: $1 does not have $expected. Settings: $state"; exit 1
    fi
  done
  if ! printf '%s' "$state" | grep -q 'UPDATE_PASSWORD'; then
    echo "FAIL: $1 does not have to change the password at the first sign-in. Set a temporary password."; exit 1
  fi
  if ! kcadm get "users/$id/credentials" -r inventory --fields type | flat | grep -q '"type":"password"'; then
    echo "FAIL: $1 has no password."; exit 1
  fi
  if ! kcadm get "users/$id/groups" -r inventory --fields name | flat | grep -q '"name":"warehouse"'; then
    echo "FAIL: $1 is not a member of the group warehouse."; exit 1
  fi
}
check_user erin Erin Lind
check_user frank Frank Moss
echo "PASS: erin and frank are onboarded."
exit 0
