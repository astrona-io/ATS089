# The Realm-Management Roles

A role of the `realm-management` client allows a group of Admin API calls. The names follow a pattern: `view-` roles read, `manage-` roles change and `query-` roles allow search calls. This part lists the roles, shows which ones go together and assigns them with `kcadm.sh`.

## The roles

| Role | What it allows |
| --- | --- |
| `view-users`, `manage-users`, `query-users` | Read users, change and create users and reset passwords, search for users |
| `query-groups` | Search groups |
| `view-clients`, `manage-clients`, `query-clients`, `create-client` | Read, change, search and create clients |
| `view-events`, `manage-events` | Read events and admin events, change the event settings and clear events |
| `view-realm`, `manage-realm` | Read the realm settings, change them |
| `view-identity-providers`, `manage-identity-providers` | Read and change identity providers |
| `view-organizations`, `manage-organizations`, `query-organizations` | Read, change and search organizations |
| `view-authorization`, `manage-authorization` | Read and change authorization settings |
| `impersonation` | Sign in as another user |
| `query-realms` | List realms |
| `realm-admin` | Everything above |

Give the `view-` and `query-` roles together with a `manage-` role. The Admin Console and many API calls need to find and read a resource before they can change it, so a person who manages users usually needs `query-users` and `view-users` too.

## Choosing roles for a task

Start from the task. A help desk that resets passwords needs `query-users`, `view-users` and `manage-users`. An auditor needs `view-events` and `view-users`. Add roles only when a call fails with `403`, and add the narrowest role that fixes it. Never use `impersonation` for a help desk unless the work is to sign in as the user.

## Assigning roles with kcadm

The command `add-roles` takes the user, the client and one or more roles. Create a user and give the help desk roles:

<!-- astrona:playground:renew -->

```sh
NAMESPACE=admin-delegation-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
kcadm add-roles -r inventory --uusername helpdesk --cclientid realm-management \
  --rolename query-users --rolename view-users --rolename manage-users
```

Read what the user holds. The path lists the roles assigned directly:

```sh
HD=$(kcadm get users -r inventory -q username=helpdesk -q exact=true --fields id --format csv --noquotes | tr -d '\r')
RM=$(kcadm get clients -r inventory -q clientId=realm-management --fields id --format csv --noquotes | tr -d '\r')
kcadm get "users/$HD/role-mappings/clients/$RM" -r inventory --fields name
```

The list shows the three roles. To take one away, use `remove-roles` with the same options:

```sh
kcadm remove-roles -r inventory --uusername helpdesk --cclientid realm-management --rolename manage-users
```

Roles can also be given to a group, so every member holds them. Prefer a group for a team and a user for one person.

## Common pitfalls

> [!WARNING]
> - **Giving `manage-users` without `query-users` and `view-users`.** The person cannot find the users to manage.
> - **Adding a `manage-` role to see something.** Use the `view-` role when only reading is needed.
> - **Forgetting `--cclientid realm-management`.** Without it the command looks for a realm role.
> - **Giving `impersonation` for password resets.** `manage-users` already resets passwords.
