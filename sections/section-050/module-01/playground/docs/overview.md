# Overview: Configure Login, Email And Display Settings Of A Realm (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, deploys Keycloak and creates the starting state, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- Namespace **`realm-settings-demo`** with the pods `keycloak` (Keycloak 26.8.1 in development mode, Service `keycloak` on port `8080`) and `tester` (a client pod with `curl` and `jq`).
- In Keycloak: the realm `inventory` with the user `alice` (password `alice-password`) and the confidential client `inventory-web` (secret `inventory-web-secret`).
- The administrator of the `master` realm is `admin` with the password `admin`. These are lab-only credentials.

## Helpers

Paste these once in each new terminal. `kcadm` runs Keycloak's administration command-line tool inside the Keycloak pod.

```sh
NAMESPACE=realm-settings-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
```

## Practice tasks

- Turn on registration and the forgotten password link, and find both links on the sign-in page with `curl`.
- Set `duplicateEmailsAllowed=true` and read `loginWithEmailAllowed` again.
- Set an SMTP server, turn on `verifyEmail`, create a user with an unverified email and read the user's `emailVerified`.
- Enable Danish and request the sign-in page with `Accept-Language: da`.
- Add a realm attribute and read the realm back.
