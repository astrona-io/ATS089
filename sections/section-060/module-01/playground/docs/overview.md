# Overview: Group Users Into Organizations (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, deploys Keycloak and creates the starting state, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- Namespace **`orgs-demo`** with the pods `keycloak` (Keycloak 26.8.1 in development mode, Service `keycloak` on port `8080`) and `tester` (a client pod with `curl` and `jq`).
- In Keycloak: the realm `inventory` with the users `alice` (password `alice-password`) and `bob` (password `bob-password`) and the public client `inventory-cli` with direct access grants on. Organizations are off.
- The administrator of the `master` realm is `admin` with the password `admin`. These are lab-only credentials.

## Helpers

Paste these once in each new terminal. `kcadm` runs Keycloak's administration command-line tool inside the Keycloak pod.

```sh
NAMESPACE=orgs-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
```

## Practice tasks

- Turn organizations on and create the organization `acme`.
- Set a domain and an attribute on `acme`, and read them back.
- Add `alice` as a member, list the members and remove her again.
- Request a token with the scope `organization:acme` and read the `organization` claim.
- Request a token for a user who is not a member and read the error.
