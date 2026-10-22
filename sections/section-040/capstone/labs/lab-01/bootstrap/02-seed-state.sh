#!/usr/bin/env bash
# Creates the starting state for ats-089-capstone-040.
#
# Creates the realm inventory and the LDAP provider openldap with two faults:
# the bind credential is an old password, and the users DN points at
# ou=users, which does not exist. There is no group mapper.
#
# The repairs are NOT made here — they are the task.
set -euo pipefail

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

echo "[setup] Creating the inventory realm, the user alice and inventory-cli..."
kcadm get realms/inventory >/dev/null 2>&1 || kcadm create realms -s realm=inventory -s enabled=true
create_user inventory alice alice-password Alice Example
if [ -z "$(client_uuid inventory inventory-cli)" ]; then
  kcadm create clients -r inventory -s clientId=inventory-cli -s enabled=true \
    -s publicClient=true -s standardFlowEnabled=false -s directAccessGrantsEnabled=true
fi

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

[ -n "$(ldap_provider_id)" ] || create_ldap_provider old-ldap-password "ou=users,dc=example,dc=org"
kubectl -n "$NAMESPACE" create configmap capstone-baseline \
  --from-literal=provider="$(ldap_provider_id)" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "[lab] Starting state ready."
kubectl -n "$NAMESPACE" get pods
