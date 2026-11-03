# Who Can Administer A Realm

Before you give anyone administration rights, you need to know what kinds exist. Keycloak has three, and they differ in how far their rights reach. This part names them, shows where each signs in and explains why the first two are not limited by anything you configure later.

## The three kinds

A **server administrator** has the `admin` role in the `master` realm. The account can manage every realm on the server. The `admin` user of this course is one.

A **realm administrator** has the client role `realm-admin` of the client `realm-management` in one realm. The account has full access to that realm and to nothing else.

A **delegated realm administrator** is any other user who received some realm-management roles, or permissions from the fine-grained feature. The account can do only what the roles or permissions allow.

Server administrators and realm administrators are not affected by any limit you define for delegated administrators. Review who holds `admin` and `realm-admin` regularly, because each of them can grant themselves or others anything in their reach.

## The dedicated admin console of a realm

Each realm has its own Admin Console at `/admin/<realm>/console`. A user of the realm `inventory` who holds realm-management roles signs in there with the realm's own users, not with `admin` of the `master` realm. The console shows only the parts that the roles allow. The REST API at `/admin/realms/<realm>` follows the same roles.

## Finding the realm-management client

The roles live in a built-in client of every realm. Paste the helper and read it:

<!-- astrona:playground:renew -->

```sh
NAMESPACE=admin-delegation-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
kcadm get clients -r inventory -q clientId=realm-management --fields id,clientId
```

The result is one client with the client ID `realm-management`. List its roles:

```sh
RM=$(kcadm get clients -r inventory -q clientId=realm-management --fields id --format csv --noquotes | tr -d '\r')
kcadm get "clients/$RM/roles" -r inventory --fields name
```

The list includes `realm-admin`, `view-users`, `manage-users`, `view-events` and others. The next part sorts them by task.

## Common pitfalls

> [!WARNING]
> - **Treating the `master` admin as a daily account.** It reaches every realm. Use a realm account for daily work.
> - **Giving `realm-admin` because it is easy.** It includes every other role.
> - **Looking for the roles in the realm roles list.** They are client roles of `realm-management`.
> - **Assuming a limit applies to a realm administrator.** Limits apply only to delegated administrators.
