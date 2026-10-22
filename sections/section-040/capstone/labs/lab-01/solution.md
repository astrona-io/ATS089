# Solution: Fix A Federation That Lost Its Users

Work the task yourself first. Running `astrona submit -c sections/section-040/capstone/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks four things: tokens for both directory users, the group membership in Keycloak, the repaired provider, and the group mapper.

## Step 1: Set up the helpers and reproduce the failure

```sh
NAMESPACE=federationcapstone-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
kubectl -n "$NAMESPACE" exec deploy/tester -- curl -s \
  http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
  -d grant_type=password -d client_id=inventory-cli -d username=ldap-ana -d password=ldap-password \
  | jq '{error, error_description}'
```

The answer is `invalid_grant` with a description that the user or the credentials are invalid. Keycloak could not find or check `ldap-ana` in the directory.

## Step 2: Compare the provider with the directory

```sh
PROVIDER_ID="$(kcadm get components -r inventory -q name=openldap -q type=org.keycloak.storage.UserStorageProvider --fields id --format csv --noquotes | tr -d '\r')"
kcadm get "components/$PROVIDER_ID" -r inventory | jq '.config | {connectionUrl, bindDn, usersDn, editMode}'
kcadm get components -r inventory -q parent="$PROVIDER_ID" --fields name,providerId
```

Two settings do not match the directory, and one piece is missing:

- `usersDn` is `ou=users,dc=example,dc=org`, but the users are under `ou=people`.
- The bind credential is masked in the output, so you cannot read it. The Keycloak log shows that the bind as `cn=admin,dc=example,dc=org` fails, which means the stored password is an old one: `kubectl -n "$NAMESPACE" logs deploy/keycloak | grep -i ldap | tail -5`.
- The mapper list has the attribute mappers but no `group-ldap-mapper`.

## Step 3: Repair the provider

`kcadm update` reads the component, changes the two values, and sends it back. The masked credential is replaced with the real one:

```sh
kcadm update "components/$PROVIDER_ID" -r inventory \
  -s 'config.bindCredential=["ldap-admin-password"]' \
  -s 'config.usersDn=["ou=people,dc=example,dc=org"]'
```

## Step 4: Add the group mapper

```sh
kcadm create components -r inventory -s name=ldap-groups -s providerId=group-ldap-mapper \
  -s providerType=org.keycloak.storage.ldap.mappers.LDAPStorageMapper -s parentId="$PROVIDER_ID" \
  -s 'config."groups.dn"=["ou=groups,dc=example,dc=org"]' \
  -s 'config."group.name.ldap.attribute"=["cn"]' \
  -s 'config."group.object.classes"=["groupOfNames"]' \
  -s 'config."membership.ldap.attribute"=["member"]' \
  -s 'config."membership.attribute.type"=["DN"]' \
  -s 'config."membership.user.ldap.attribute"=["uid"]' \
  -s 'config.mode=["READ_ONLY"]' \
  -s 'config."user.roles.retrieve.strategy"=["LOAD_GROUPS_BY_MEMBER_ATTRIBUTE"]'
```

## Step 5: Synchronize users and groups

```sh
kcadm create "user-storage/$PROVIDER_ID/sync?action=triggerFullSync" -r inventory
MAPPER_ID="$(kcadm get components -r inventory -q name=ldap-groups -q parent="$PROVIDER_ID" --fields id --format csv --noquotes | tr -d '\r')"
kcadm create "user-storage/$PROVIDER_ID/mappers/$MAPPER_ID/sync?direction=fedToKeycloak" -r inventory
```

## Step 6: Prove it

```sh
for user in ldap-ana ldap-ben; do
  printf '%s: ' "$user"
  kubectl -n "$NAMESPACE" exec deploy/tester -- curl -s \
    http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=password -d client_id=inventory-cli -d username="$user" -d password=ldap-password \
    | jq -r 'if .access_token then "token" else .error_description end'
  USER_ID="$(kcadm get users -r inventory -q username="$user" -q exact=true --fields id --format csv --noquotes | tr -d '\r')"
  kcadm get "users/$USER_ID/groups" -r inventory --fields name
done
```

Both users get a token. `ldap-ana`'s groups list `warehouse`; `ldap-ben`'s list is empty.

## Step 7: Submit

```sh
astrona submit -c sections/section-040/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Delete the provider and create a new one | every linked user loses its link, and the grader checks the original ID |
| Switch to `WRITABLE` | the sign-in problem stays, and Keycloak may now write to the directory |
| Create the group `warehouse` by hand in Keycloak | the membership no longer follows the directory |
| Set the users DN to the base DN | with a one-level search, no users are found under `dc=example,dc=org` |
