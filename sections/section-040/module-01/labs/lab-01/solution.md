# Solution: Federate An LDAP Directory

Work the task yourself first. Running `astrona submit -c sections/section-040/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the provider's settings, a token for `ldap-ana`, and that both users are linked to the provider.

## Step 1: Set up the helpers and look at the directory

```sh
NAMESPACE=ldap-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
kubectl -n "$NAMESPACE" exec deploy/openldap -- ldapsearch -x -LLL -H ldap://localhost \
  -D cn=admin,dc=example,dc=org -w ldap-admin-password -b ou=people,dc=example,dc=org uid
```

The search lists two entries, `uid=ldap-ana` and `uid=ldap-ben`, under `ou=people,dc=example,dc=org`. That confirms the users DN and the bind credentials before Keycloak uses them.

## Step 2: Create the provider

A provider is a component whose parent is the realm. Every `config` value is a list:

```sh
REALM_ID="$(kcadm get realms/inventory --fields id --format csv --noquotes | tr -d '\r')"
kcadm create components -r inventory -s name=openldap -s providerId=ldap \
  -s providerType=org.keycloak.storage.UserStorageProvider -s parentId="$REALM_ID" \
  -s 'config.enabled=["true"]' -s 'config.vendor=["other"]' \
  -s 'config.connectionUrl=["ldap://openldap:389"]' -s 'config.authType=["simple"]' \
  -s 'config.bindDn=["cn=admin,dc=example,dc=org"]' -s 'config.bindCredential=["ldap-admin-password"]' \
  -s 'config.usersDn=["ou=people,dc=example,dc=org"]' \
  -s 'config.usernameLDAPAttribute=["uid"]' -s 'config.rdnLDAPAttribute=["uid"]' \
  -s 'config.uuidLDAPAttribute=["entryUUID"]' \
  -s 'config.userObjectClasses=["inetOrgPerson, organizationalPerson"]' \
  -s 'config.searchScope=["1"]' -s 'config.editMode=["READ_ONLY"]' \
  -s 'config.importEnabled=["true"]'
```

## Step 3: Synchronize the users

```sh
PROVIDER_ID="$(kcadm get components -r inventory -q name=openldap -q type=org.keycloak.storage.UserStorageProvider --fields id --format csv --noquotes | tr -d '\r')"
kcadm create "user-storage/$PROVIDER_ID/sync?action=triggerFullSync" -r inventory
kcadm get users -r inventory -q username=ldap --fields username,federationLink
```

The result of the synchronization counts two added users, and the user list shows both with `federationLink` set to `PROVIDER_ID`.

## Step 4: Prove the sign-in

```sh
kubectl -n "$NAMESPACE" exec deploy/tester -- curl -s \
  http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
  -d grant_type=password -d client_id=inventory-cli -d username=ldap-ana -d password=ldap-password \
  | jq -r '.access_token | split(".")[1] | gsub("-";"+") | gsub("_";"/") | . + ("=" * ((4 - length % 4) % 4)) | @base64d | fromjson | .preferred_username'
```

The command prints `ldap-ana`. Keycloak checked her password by binding to LDAP as her.

## Step 5: Submit

```sh
astrona submit -c sections/section-040/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Create `ldap-ana` as a local user with the same password | she signs in, but with a second password the directory does not control; the grader checks `federationLink` |
| Use `WRITABLE` | Keycloak may write user changes into the directory the directory team owns |
| Set the users DN to `dc=example,dc=org` with a one-level search | Keycloak looks only directly under the base DN and finds no users |
| Skip the synchronization | `ldap-ana` is imported at her first sign-in, but `ldap-ben` is not, and the grader looks for both |
