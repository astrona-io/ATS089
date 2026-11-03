#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab stays unsolved for the student.
# Taken from solution.md - if one changes, change the other.
set -eu

NAMESPACE="orgs-demo"

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

kcadm update realms/inventory -s organizationsEnabled=true
kcadm create organizations -r inventory -s name="Acme Corporation" -s alias=acme -s enabled=true \
  -s 'domains=[{"name":"acme.example"}]'
kcadm create organizations -r inventory -s name=Globex -s alias=globex -s enabled=true \
  -s 'domains=[{"name":"globex.example"}]'
org_id() { kcadm get organizations -r inventory | in_tester_jq -r --arg a "$1" '.[] | select(.alias==$a) | .id'; }
kcadm create "organizations/$(org_id acme)/members" -r inventory -b "\"$(user_id inventory alice)\""
kcadm create "organizations/$(org_id globex)/members" -r inventory -b "\"$(user_id inventory bob)\""
