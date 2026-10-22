# Prerequisites

Before starting this lab you should be able to:

- Request a token with the password grant and decode it with `jq`.
- Read and change role mappings, composite roles and client scopes with `kcadm.sh` or the Admin Console.
- Explain how `realm_access` and `resource_access` reach an access token.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Keycloak 26.8.1** in development mode in the namespace **`rolescapstone-demo`**, behind the Service `keycloak` on port `8080`.
- A `tester` pod with `curl` and `jq`.
- The realm `inventory` with the users `alice` and `bob`, the clients `inventory-cli` and `inventory-api`, the realm role `warehouse-clerk` and the groups `warehouse` and `auditors`. The administrator of the `master` realm is `admin` with the password `admin` (lab-only credentials).

Nothing the task asks you to create has been created for you.

## Working rules

- Everything is graded on the **final state** of Keycloak and the cluster, so run your checks again at the end and leave the fix in place.
- Change one setting at a time and test again. A second change you are not sure about makes the first one impossible to check.
- `kubectl`, `curl` and `jq` are available, and `kcadm.sh` is in the Keycloak pod at `/opt/keycloak/bin/kcadm.sh`. You may also use the Admin Console through `kubectl -n rolescapstone-demo port-forward svc/keycloak 8080:8080`.
