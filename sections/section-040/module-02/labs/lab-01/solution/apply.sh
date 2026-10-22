#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab stays broken for the student.
# Taken from solution.md - if one changes, change the other.
set -eu

NAMESPACE="broker-demo"

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

if [ -z "$(client_uuid partner inventory-broker)" ]; then
  kcadm create clients -r partner -s clientId=inventory-broker -s enabled=true \
    -s publicClient=false -s secret=inventory-broker-secret \
    -s standardFlowEnabled=true -s directAccessGrantsEnabled=false \
    -s 'redirectUris=["http://localhost:8080/realms/inventory/broker/partner/endpoint"]'
fi
kcadm create identity-provider/instances -r inventory -s alias=partner -s providerId=oidc \
  -s enabled=true -s displayName=Partner -s firstBrokerLoginFlowAlias="first broker login" \
  -s config.issuer=http://localhost:8080/realms/partner \
  -s config.authorizationUrl=http://localhost:8080/realms/partner/protocol/openid-connect/auth \
  -s config.tokenUrl=http://localhost:8080/realms/partner/protocol/openid-connect/token \
  -s config.userInfoUrl=http://localhost:8080/realms/partner/protocol/openid-connect/userinfo \
  -s config.jwksUrl=http://localhost:8080/realms/partner/protocol/openid-connect/certs \
  -s config.logoutUrl=http://localhost:8080/realms/partner/protocol/openid-connect/logout \
  -s config.useJwksUrl=true -s config.validateSignature=true \
  -s config.clientId=inventory-broker -s config.clientSecret=inventory-broker-secret \
  -s config.clientAuthMethod=client_secret_post -s config.defaultScope="openid profile email" \
  -s config.syncMode=IMPORT
kcadm create identity-provider/instances/partner/mappers -r inventory \
  -s name=partner-user-role -s identityProviderAlias=partner \
  -s identityProviderMapper=hardcoded-role-idp-mapper \
  -s config.role=partner-user -s config.syncMode=INHERIT
