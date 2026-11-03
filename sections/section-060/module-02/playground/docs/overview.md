# Overview: Delegate Administration With Realm-Management Roles (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, deploys Keycloak and creates the starting state, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- Namespace **`admin-delegation-demo`** with the pods `keycloak` (Keycloak 26.8.1 in development mode, Service `keycloak` on port `8080`) and `tester` (a client pod with `curl` and `jq`).
- In Keycloak: the realm `inventory` with the users `helpdesk`, `auditor`, `alice` and `bob`. The password of each user is the username followed by `-password`. No user holds an administration role.
- The administrator of the `master` realm is `admin` with the password `admin`. These are lab-only credentials.

## Helpers

Paste these once in each new terminal. `kcadm` runs Keycloak's administration command-line tool inside the Keycloak pod.

```sh
NAMESPACE=admin-delegation-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
```

## Practice tasks

- List the roles of the client `realm-management`.
- Give `helpdesk` the roles `query-users`, `view-users` and `manage-users`.
- Call the Admin API as `helpdesk` and compare `GET users`, `POST users` with `{}` and `GET events`.
- Give `auditor` the roles `view-events` and `view-users` and repeat the calls.
- Remove a role and request a new token to see the effect.
