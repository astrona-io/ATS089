# Edit Modes, Mappers And Synchronization

A connected directory raises three questions at once. If a user changes their email in Keycloak's account console, should it change in LDAP too? How do LDAP groups become Keycloak groups? And when does Keycloak notice that someone was added to the directory? This part answers all three with the provider's edit mode, its mappers and its synchronization settings.

## Edit modes

The **edit mode** decides what Keycloak does when someone changes a federated user:

| Edit mode | Change in Keycloak | Use it when |
| --- | --- | --- |
| `READ_ONLY` | Refused for mapped attributes and the password | The directory is the source of truth and other tools maintain it |
| `WRITABLE` | Written back to LDAP | Keycloak is allowed to maintain the directory |
| `UNSYNCED` | Stored in Keycloak's copy only; LDAP keeps the old value | Users may change data Keycloak keeps for itself, and LDAP must not be touched |

Paste the helpers for this part. `kcadm` runs Keycloak's administration command-line tool inside the Keycloak pod. `user_id` prints a user's ID. The provider from the earlier work must exist, so create it first if your playground does not have it:

<!-- astrona:playground:renew -->

```sh
NAMESPACE=ldap-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
user_id() {
  kcadm get users -r inventory -q username="$1" -q exact=true --fields id --format csv --noquotes | tr -d '\r'
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
PROVIDER_ID="$(kcadm get components -r inventory -q name=openldap -q type=org.keycloak.storage.UserStorageProvider --fields id --format csv --noquotes | tr -d '\r')"
echo "provider: $PROVIDER_ID"
```

If the last line prints an empty provider, create the provider and synchronize it with the commands that connected Keycloak to OpenLDAP, then come back. Now try to change `ldap-ana`'s last name in Keycloak:

```sh
kcadm update "users/$(user_id ldap-ana)" -r inventory -s lastName=Changed
```

Keycloak refuses the change with an error: the provider is `READ_ONLY`, so the mapped attribute `lastName` cannot be changed through Keycloak. That is the point of read-only federation: a change must happen in the directory, where it belongs.

## Mappers

A **mapper** copies one thing between an LDAP entry and a Keycloak user. The default mappers copy attributes. Other mapper types copy more:

| Mapper type | What it copies |
| --- | --- |
| `user-attribute-ldap-mapper` | One LDAP attribute to one user attribute |
| `full-name-ldap-mapper` | One LDAP attribute, such as `cn`, to first and last name together |
| `group-ldap-mapper` | LDAP groups to Keycloak groups, with their members |
| `role-ldap-mapper` | LDAP groups to Keycloak roles |
| `hardcoded-ldap-role-mapper` | A fixed role to every user of the provider |

Add a group mapper, so the LDAP group `warehouse` becomes a Keycloak group. Its settings say where the groups are, which attribute names them, and how membership is stored. Like the provider, every value is a list, and keys with dots are written in quotes:

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

`membership.attribute.type` `DN` says that the `member` attribute holds full DNs, as you saw in the directory. The mapper's `mode` follows the same rule as the provider's edit mode.

## Synchronization

Keycloak reads LDAP in three situations: when a user signs in or is looked up, when you start a synchronization, and on a schedule. A group mapper has its own synchronization. Synchronize the groups from LDAP into Keycloak, and read `ldap-ana`'s groups:

```sh
MAPPER_ID="$(kcadm get components -r inventory -q name=ldap-groups -q parent="$PROVIDER_ID" --fields id --format csv --noquotes | tr -d '\r')"
kcadm create "user-storage/$PROVIDER_ID/mappers/$MAPPER_ID/sync?direction=fedToKeycloak" -r inventory
kcadm get "users/$(user_id ldap-ana)/groups" -r inventory --fields name
```

The last command lists `warehouse`. `ldap-ben` has no groups, because LDAP lists only `ldap-ana` as a member.

The schedule is two provider settings. `fullSyncPeriod` runs a full synchronization every given number of seconds, and `changedSyncPeriod` copies only entries changed since the last run. Both are `-1`, which means off, unless you set them. A periodic changed-users synchronization keeps new directory users visible in Keycloak's user list without waiting for them to sign in.

You now know how to decide who may change a federated user, how to bring groups across with a mapper, and how and when Keycloak reads the directory. That covers the whole life of a federated user, from the directory entry to the token.

## Common pitfalls

> [!WARNING]
> - **Switching to `WRITABLE` to make a change work.** Keycloak then writes to the directory for every change, including from users. Make the change in LDAP instead.
> - **Using `UNSYNCED` and expecting LDAP to follow.** Changes stay in Keycloak's copy, and the two drift apart.
> - **Mixing up the group mapper's membership type.** If `member` holds full DNs, the type must be `DN`; with `UID`, Keycloak finds no members.
> - **Expecting groups without a group synchronization.** Run the mapper's sync, or let users sign in, before you look for the groups.
