# Overview: Control How Users Sign In With Flows, OTP And Passkeys (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, deploys Keycloak, creates a realm with two users and the realm role `stock-admin`, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- Namespace **`flows-demo`** with these workloads:

  | Workload | What it is |
  | --- | --- |
  | `keycloak` | One Keycloak 26.8.1 pod in development mode, behind the Service `keycloak` on port `8080` |
  | `tester` | Client pod with `curl` and `jq`; send token requests from here |

- Inside Keycloak, the realm **`inventory`**:

  | Keycloak object | What it is |
  | --- | --- |
  | user `alice` | Password `alice-password`, no extra roles |
  | user `bob` | Password `bob-password`, holds the realm role `stock-admin` |
  | client `inventory-cli` | Public client with direct access grants on |
  | flows | Only the built-in flows; `browser` and `direct grant` are bound |

- The administrator of the `master` realm is `admin` with the password `admin`. These are lab-only credentials.

## Helpers

Paste these once in each new terminal. `kcadm` runs Keycloak's administration command-line tool inside the Keycloak pod. `in_tester_jq` runs `jq` inside the `tester` pod. `get_user_token` prints the response of the password grant; it runs the `direct grant` flow, and OAuth 2.1 drops that grant, so it is used here only for testing.

```sh
NAMESPACE=flows-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
in_tester_jq() {
  kubectl -n "$NAMESPACE" exec -i deploy/tester -- jq "$@"
}
get_user_token() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- curl -s \
    http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=password -d client_id=inventory-cli -d username="$1" -d password="$2"
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
```

To see the sign-in forms, run `kubectl -n flows-demo port-forward svc/keycloak 8080:8080` in a second terminal and open `http://localhost:8080/realms/inventory/account/`. Use a private browser window for each user, so one user's cookie does not sign in the next one.

## Practice tasks

- Read the executions of the `direct grant` flow and compare them with the `browser` flow.
- Add `passwordHistory(3)` to the password policy and try to set the same password twice.
- Change the OTP policy to eight digits, set up OTP for `bob` in the browser, and look at the code your app shows.
- Copy the browser flow, add the WebAuthn Passwordless Authenticator as an alternative to the password form, bind it, and register a passkey for `bob` with your laptop's authenticator.
- Bind a broken copy of the browser flow on purpose, see what happens in the browser, and bind `browser` again with `kcadm update realms/inventory -s browserFlow=browser`.
