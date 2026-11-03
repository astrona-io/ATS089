# Overview: Control Sessions, Token Lifespans And Offline Access (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, deploys Keycloak and creates the starting state, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- Namespace **`sessions-demo`** with the pods `keycloak` (Keycloak 26.8.1 in development mode, Service `keycloak` on port `8080`) and `tester` (a client pod with `curl` and `jq`).
- In Keycloak: the realm `inventory` with the users `alice` (password `alice-password`) and `bob` (password `bob-password`), and the public clients `inventory-cli` and `inventory-batch`, both with direct access grants on.
- The administrator of the `master` realm is `admin` with the password `admin`. These are lab-only credentials.

## Helpers

Paste these once in each new terminal. `kcadm` runs Keycloak's administration command-line tool inside the Keycloak pod.

```sh
NAMESPACE=sessions-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
```

## Practice tasks

- Set the SSO idle limit larger than the maximum and read the error.
- Set `accessTokenLifespan` to 60 and prove it with the `exp` minus `iat` of a token.
- Give `inventory-batch` its own lifespan and compare the two clients.
- Request an offline token for `bob`, find the offline session and revoke it.
- Create sessions for both users, then end them with `sessions/<id>`, `users/<id>/logout` and `logout-all`.
