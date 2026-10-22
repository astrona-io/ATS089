# Connecting Keycloak To OpenLDAP

You know the settings; now Keycloak needs them as a provider. This part creates a read-only LDAP provider in the realm `inventory` with `kcadm.sh`, looks at what Keycloak adds by itself, synchronizes the users, and signs a directory user in with a password that only LDAP knows.

## Creating the provider

A federation provider is a **component** of the realm: an object with a `providerId` (here `ldap`), a `providerType` (the User Storage SPI), a `parentId` (the realm's ID) and a `config` map. Every value in `config` is a list, which is why each value below is written in brackets.

Paste the helpers for this part. `kcadm` runs Keycloak's administration command-line tool inside the Keycloak pod. `get_user_token` sends the password grant from the `tester` pod and prints the JSON response; OAuth 2.1 drops the password grant, and it is used here only for testing:

<!-- astrona:playground:renew -->

```sh
NAMESPACE=ldap-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
get_user_token() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- curl -s \
    http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=password -d client_id=inventory-cli -d username="$1" -d password="$2"
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
```

Look up the realm's ID, which the provider needs as its parent, and create the provider. The edit mode is `READ_ONLY`, so Keycloak never writes to the directory:

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

`kcadm.sh` prints that it created a new component and shows its ID. `searchScope` `1` means one level: Keycloak looks for users directly under the users DN, not in deeper folders. `vendor` `other` tells Keycloak this is a generic LDAP server; for Active Directory you would choose `ad`, which changes several defaults.

## What Keycloak added by itself

When it creates an LDAP provider, Keycloak also creates a set of **mappers**: rules that copy one LDAP attribute to one field of the Keycloak user. Read them. They are components too, with the provider as their parent:

```sh
PROVIDER_ID="$(kcadm get components -r inventory -q name=openldap -q type=org.keycloak.storage.UserStorageProvider --fields id --format csv --noquotes | tr -d '\r')"
kcadm get components -r inventory -q parent="$PROVIDER_ID" --fields name,providerId
```

The list holds mappers named `username`, `first name`, `last name` and `email`, of the type `user-attribute-ldap-mapper`, plus two for the creation and change dates. They map `uid`, `cn`, `sn` and `mail` to the Keycloak fields. That is why a directory user arrives with a complete profile.

## Synchronizing and signing in

With import on, Keycloak copies a user the first time that user signs in or is looked up. A **full synchronization** copies all users at once. Start one:

```sh
kcadm create "user-storage/$PROVIDER_ID/sync?action=triggerFullSync" -r inventory
kcadm get users -r inventory -q username=ldap --fields username,email,federationLink
```

The first command answers with a short result that counts the users added, here two. The second lists `ldap-ana` and `ldap-ben`, each with `federationLink` set to the provider's ID.

Now sign `ldap-ana` in. Her password exists only in LDAP:

```sh
get_user_token ldap-ana ldap-password | jq -r '.access_token | split(".")[1] | gsub("-";"+") | gsub("_";"/") | . + ("=" * ((4 - length % 4) % 4)) | @base64d | fromjson | {preferred_username, email}'
```

The result shows `preferred_username` `ldap-ana` and her LDAP email address. Keycloak found her through its own bind, checked her password by binding as her, and issued the tokens.

You can now connect a directory, read the mappers Keycloak adds, synchronize the users, and prove a federated sign-in. The open question is what happens when someone wants to change a directory user, and how groups come across.

## Your mission: Federate An LDAP Directory

You can now create an LDAP provider, synchronize it, and sign a directory user in. The graded lab gives you a realm with no federation and the same OpenLDAP server, and asks you to connect them read-only so that both directory users are linked and can sign in.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-089-playground-040-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS089.git -c sections/section-040/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-040/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-089-lab-040-01
astrona start ats-089-playground-040-01
```

## Common pitfalls

> [!WARNING]
> - **Forgetting the brackets in `config` values.** Every value in a component's `config` is a list: `["READ_ONLY"]`, not `READ_ONLY`.
> - **Pointing the users DN at the base DN with a one-level search.** Users under `ou=people` are two levels down from `dc=example,dc=org`; Keycloak finds nobody.
> - **Testing with a user Keycloak already holds locally.** A local user with the same username shadows the directory user. Check `federationLink`.
> - **Expecting users to appear before a sign-in or a sync.** With import on, a user is copied when first used or at a synchronization.
