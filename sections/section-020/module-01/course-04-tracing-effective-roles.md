# Tracing Effective Roles

A user reports that an API refuses them, and the role they should hold is nowhere in their role list. The cause is usually in the path between the user and the role: a group, a parent group, a composite role or a default role. This part gives a method to trace that path from the terminal, so you find the source of a role instead of guessing.

## Direct, group and effective roles

A user's **direct** roles are the ones mapped to the user. Their **effective** roles are everything that applies: direct roles, the roles of every group the user belongs to (including parent groups), the roles inside composite roles, and the default roles of the realm. A token carries the effective roles that the client scopes allow. When a role is missing from the token, find out first whether it is missing from the effective set or only filtered out by the client.

Paste the helper and make sure the pieces exist. The commands skip what already exists:

<!-- astrona:playground:renew -->

```sh
NAMESPACE=roles-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
kcadm get groups -r inventory -q search=warehouse --fields name | grep -q warehouse || kcadm create groups -r inventory -s name=warehouse
```

## Reading the roles of a user in layers

Read the direct client roles, then the effective client roles. The `--effective` option expands composites and groups:

```sh
kcadm get-roles -r inventory --uusername alice --cclientid inventory-api
kcadm get-roles -r inventory --uusername alice --cclientid inventory-api --effective
```

The first list is shorter. Any role that appears only in the second came through a group, a composite or a default role. Do the same for realm roles by leaving out `--cclientid`:

```sh
kcadm get-roles -r inventory --uusername alice --effective
```

## Finding which group gives a role

List the groups of the user, then the roles of each group:

```sh
ALICE=$(kcadm get users -r inventory -q username=alice -q exact=true --fields id --format csv --noquotes | tr -d '\r')
kcadm get "users/$ALICE/groups" -r inventory --fields id,name,path
kcadm get-roles -r inventory --gname warehouse
```

The path of a subgroup shows its parents, such as `/warehouse/night`. The roles of every parent apply to the subgroup members too. Check each parent with `--gname warehouse` and with the subgroup path.

## Finding which composite contains a role

A composite role lists the roles it contains. Read the composite, not the user:

```sh
kcadm get "roles/warehouse-clerk/composites" -r inventory --fields name,containerId
```

If the missing role is in this list, the user needs the composite, not the role itself. If it is not, the composite was built wrong.

## From effective roles to the token

When the effective roles contain the role but the token does not, look at the client side: the client scope `roles`, its mappers and the setting **Full scope allowed** of the client. A client with full scope off sees only the roles that its scopes allow. That check is the last step of the trace and the one people skip.

You now have a method with four steps: direct, group, composite, client scope. Use the same order every time.

## Common pitfalls

> [!WARNING]
> - **Reading only the direct roles.** Most roles arrive through groups and composites.
> - **Forgetting parent groups.** A subgroup inherits the roles of every parent.
> - **Blaming the user mapping when the client filters.** Check the client scope after the effective roles.
> - **Adding the role directly to hide the cause.** The next user with the same path has the same problem.
