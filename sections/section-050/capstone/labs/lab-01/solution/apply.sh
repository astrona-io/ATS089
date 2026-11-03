#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab stays unsolved for the student.
# Taken from solution.md - if one changes, change the other.
set -eu

NAMESPACE="realm-audit-capstone"

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
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin

kcadm update events/config -r inventory -s eventsEnabled=true -s eventsExpiration=604800 \
  -s 'enabledEventTypes=["LOGIN","LOGIN_ERROR"]'
kubectl -n "$NAMESPACE" exec deploy/tester -- curl -s -o /dev/null \
  http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
  -d grant_type=password -d client_id=inventory-cli -d username=bob -d password=bob-password
kcadm update "users/$(user_id inventory bob)" -r inventory -s enabled=true
kcadm update realms/inventory -s resetPasswordAllowed=true -s rememberMe=true \
  -s ssoSessionIdleTimeout=1800 -s accessTokenLifespan=300
