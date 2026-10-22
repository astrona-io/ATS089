#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab stays broken for the student.
# Taken from solution.md - if one changes, change the other.
set -eu

NAMESPACE="federationcapstone-demo"

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

create_ldap_provider() {
  # create_ldap_provider BIND_PASSWORD USERS_DN: a read-only LDAP provider named openldap.
  local realm_id
  realm_id="$(kcadm get realms/inventory --fields id --format csv --noquotes | tr -d '\r')"
  kcadm create components -r inventory -s name=openldap -s providerId=ldap \
    -s providerType=org.keycloak.storage.UserStorageProvider -s parentId="$realm_id" \
    -s 'config.enabled=["true"]' -s 'config.priority=["1"]' \
    -s 'config.vendor=["other"]' -s 'config.connectionUrl=["ldap://openldap:389"]' \
    -s 'config.authType=["simple"]' -s 'config.bindDn=["cn=admin,dc=example,dc=org"]' \
    -s "config.bindCredential=[\"$1\"]" -s "config.usersDn=[\"$2\"]" \
    -s 'config.usernameLDAPAttribute=["uid"]' -s 'config.rdnLDAPAttribute=["uid"]' \
    -s 'config.uuidLDAPAttribute=["entryUUID"]' \
    -s 'config.userObjectClasses=["inetOrgPerson, organizationalPerson"]' \
    -s 'config.searchScope=["1"]' -s 'config.editMode=["READ_ONLY"]' \
    -s 'config.importEnabled=["true"]' -s 'config.syncRegistrations=["false"]' \
    -s 'config.pagination=["true"]' -s 'config.useTruststoreSpi=["always"]' \
    -s 'config.fullSyncPeriod=["-1"]' -s 'config.changedSyncPeriod=["-1"]' \
    -s 'config.cachePolicy=["DEFAULT"]'
}
ldap_provider_id() {
  kcadm get components -r inventory -q name=openldap -q type=org.keycloak.storage.UserStorageProvider \
    --fields id --format csv --noquotes | tr -d '\r' | head -1
}

PROVIDER_ID="$(ldap_provider_id)"
kcadm update "components/$PROVIDER_ID" -r inventory \
  -s 'config.bindCredential=["ldap-admin-password"]' \
  -s 'config.usersDn=["ou=people,dc=example,dc=org"]'
kcadm create components -r inventory -s name=ldap-groups -s providerId=group-ldap-mapper \
  -s providerType=org.keycloak.storage.ldap.mappers.LDAPStorageMapper -s parentId="$PROVIDER_ID" \
  -s 'config."groups.dn"=["ou=groups,dc=example,dc=org"]' \
  -s 'config."group.name.ldap.attribute"=["cn"]' \
  -s 'config."group.object.classes"=["groupOfNames"]' \
  -s 'config."membership.ldap.attribute"=["member"]' \
  -s 'config."membership.attribute.type"=["DN"]' \
  -s 'config."membership.user.ldap.attribute"=["uid"]' \
  -s 'config.mode=["READ_ONLY"]' \
  -s 'config."user.roles.retrieve.strategy"=["LOAD_GROUPS_BY_MEMBER_ATTRIBUTE"]' \
  -s 'config."preserve.group.inheritance"=["true"]' \
  -s 'config."ignore.missing.groups"=["false"]' \
  -s 'config."drop.non.existing.groups.during.sync"=["false"]'
MAPPER_ID="$(kcadm get components -r inventory -q name=ldap-groups -q parent="$PROVIDER_ID" --fields id --format csv --noquotes | tr -d '\r' | head -1)"
kcadm create "user-storage/$PROVIDER_ID/sync?action=triggerFullSync" -r inventory
kcadm create "user-storage/$PROVIDER_ID/mappers/$MAPPER_ID/sync?direction=fedToKeycloak" -r inventory
