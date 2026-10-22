# Overview: Model Access With Roles, Composite Roles And Groups (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, deploys Keycloak, creates a realm with two users and an API client with two client roles, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- Namespace **`roles-demo`** with these workloads:

  | Workload | What it is |
  | --- | --- |
  | `keycloak` | One Keycloak 26.8.1 pod in development mode, behind the Service `keycloak` on port `8080` |
  | `tester` | Client pod with `curl` and `jq`; send token requests from here |

- Inside Keycloak, the realm **`inventory`**:

  | Keycloak object | What it is |
  | --- | --- |
  | users `alice`, `bob` | Passwords `alice-password` and `bob-password`; no roles beyond the default roles |
  | client `inventory-cli` | Public client with direct access grants on; it requests the tokens |
  | client `inventory-api` | The API; it defines the client roles `stock-read` and `stock-write` |

- The administrator of the `master` realm is `admin` with the password `admin`. These are lab-only credentials.

## Helpers

Paste these once in each new terminal. They need `jq` on your machine. `kcadm` runs Keycloak's administration command-line tool inside the Keycloak pod. `get_access_token` prints an access token for a user, from the password grant; OAuth 2.1 drops that grant, and it is used here only for testing. `decode_token` prints the claims of a JWT.

```sh
NAMESPACE=roles-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
get_access_token() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- curl -s \
    http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=password -d client_id=inventory-cli -d username="$1" -d password="$2" \
    | jq -r .access_token
}
decode_token() {
  jq -R 'split(".")[1] | gsub("-";"+") | gsub("_";"/") | . + ("=" * ((4 - length % 4) % 4)) | @base64d | fromjson'
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
```

Use them like this: `get_access_token alice alice-password | decode_token | jq '{realm_access, resource_access}'`.

## Practice tasks

- Add `stock-read` to `default-roles-inventory`, request a new token for `bob`, and see it appear. Then remove it.
- Build a group `auditors` with a subgroup `external`, map `stock-read` to `auditors`, put `bob` in `external`, and check `get-roles --effective` for `bob`.
- Turn off **Full scope allowed** on `inventory-cli` in the Admin Console (**Clients**, `inventory-cli`, **Client scopes**, `inventory-cli-dedicated`, **Scope**), and compare `alice`'s token before and after. Turn it back on.
- Remove the default client scope `roles` from `inventory-cli`, read a token, and add it back with `kcadm update clients/<id>/default-client-scopes/<scope id> -r inventory -n`.
- Make `warehouse-clerk` contain `stock-admin` too, and follow the expansion in a token.
