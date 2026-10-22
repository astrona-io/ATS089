# Overview: Manage Users Through Their Whole Lifecycle (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, deploys Keycloak, creates a realm with two users and a group, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- Namespace **`users-demo`** with these workloads:

  | Workload | What it is |
  | --- | --- |
  | `keycloak` | One Keycloak 26.8.1 pod in development mode (`start-dev`), behind the Service `keycloak` on port `8080` (`http`) and `9000` (`management`) |
  | `tester` | Client pod with `curl` and `jq`; send token requests from here to `http://keycloak:8080` |

- Inside Keycloak, the realm **`inventory`**, a space that holds its own users, clients and settings:

  | Keycloak object | What it is |
  | --- | --- |
  | user `alice` | Password `alice-password`, complete profile, member of `warehouse` |
  | user `bob` | Password `bob-password`, complete profile |
  | group `warehouse` | A group with `alice` as its member |
  | client `inventory-cli` | Public client with direct access grants on, so it can use the password grant |

- The administrator of the `master` realm is `admin` with the password `admin`. These are lab-only credentials.

Keycloak takes a few minutes to start the first time. When `kubectl -n users-demo get pods` shows `keycloak` as `1/1`, it is ready.

## Helpers

Paste these once in each new terminal. `kcadm` runs Keycloak's administration command-line tool inside the Keycloak pod; sign it in once with the `kcadm config credentials` line, and again when it answers `401`. `user_id` prints the `id` of a user in `inventory`. `get_user_token` prints the response of the password grant for a user; the password grant is only for testing from a terminal, and OAuth 2.1 drops it.

```sh
NAMESPACE=users-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
user_id() {
  kcadm get users -r inventory -q username="$1" -q exact=true --fields id --format csv --noquotes | tr -d '\r'
}
get_user_token() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- curl -s \
    http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=password -d client_id=inventory-cli -d username="$1" -d password="$2"
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
```

Use them like this: `get_user_token alice alice-password`, `kcadm get "users/$(user_id bob)" -r inventory`.

To use the Admin Console in a browser, run `kubectl -n users-demo port-forward svc/keycloak 8080:8080` in a second terminal and open `http://localhost:8080/admin/`.

## Practice tasks

- Create a user with only a username and a password, request a token for it, and read the `error_description`. Then fill in the missing profile values and try again.
- Give `bob` a temporary password and compare the token endpoint's answer with the answer for a disabled `bob`.
- Add `UPDATE_PROFILE` to `alice`'s required actions with `kcadm update ... -s 'requiredActions=["UPDATE_PROFILE"]'`, then remove it.
- Add a user attribute `department` to the user profile in the Admin Console (**Realm settings**, **User profile**), make it required for users, and see what happens to `alice`'s next token request.
- Create a group `auditors` with a subgroup `external`, put `bob` in the subgroup, and list `bob`'s groups.
- Make two sessions for `alice`, list them, and end them with the `logout` endpoint.
