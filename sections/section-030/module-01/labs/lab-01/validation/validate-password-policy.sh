#!/usr/bin/env bash
# PASS when the password policy holds length(12) and digits(1), refuses 'short1' and accepts a 22-character password with a digit.
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

POLICY="$(kcadm get realms/inventory --fields passwordPolicy --format csv --noquotes | tr -d '\r')"
case "$POLICY" in
  *"length(12)"*"digits(1)"*|*"digits(1)"*"length(12)"*) ;;
  *) echo "FAIL: the password policy is '$POLICY', expected length(12) and digits(1)."; exit 1 ;;
esac
PROBE="policy-probe-$$"
kcadm create users -r inventory -s username="$PROBE" -s enabled=true \
  -s email="$PROBE@example.com" -s firstName=Policy -s lastName=Probe >/dev/null 2>&1
cleanup() { kcadm delete "users/$(user_id inventory "$PROBE")" -r inventory >/dev/null 2>&1 || true; }
trap cleanup EXIT
if kcadm set-password -r inventory --username "$PROBE" --new-password short1 >/dev/null 2>&1; then
  echo "FAIL: the realm accepted the weak password 'short1'."; exit 1
fi
if ! kcadm set-password -r inventory --username "$PROBE" --new-password long-enough-password-1 >/dev/null 2>&1; then
  echo "FAIL: the realm refused 'long-enough-password-1', which meets the policy."; exit 1
fi
echo "PASS: the password policy refuses a weak password and accepts a strong one."
exit 0
