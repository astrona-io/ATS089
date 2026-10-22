# Prerequisites

Before starting this lab you should be able to:

- Use `kubectl exec` to run a command in a pod.
- Request a token with the password grant from a realm's token endpoint with `curl`.
- Read a user's settings with `kcadm.sh` or the Admin Console.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Keycloak 26.8.1** in development mode in the namespace **`users-demo`**, behind the Service `keycloak` on port `8080`.
- A `tester` pod with `curl` and `jq`.
- The realm `inventory` with the client `inventory-cli` and the users `alice`, `bob`, `carol` and `dave`, prepared as the task describes. The administrator of the `master` realm is `admin` with the password `admin` (lab-only credentials).

Nothing the task asks you to create has been created for you.

## Working rules

- Everything is graded on the **final state** of Keycloak and the cluster, so run your checks again at the end and leave the fix in place.
- Change one setting at a time and test again. A second change you are not sure about makes the first one impossible to check.
- `kubectl`, `curl` and `jq` are available, and `kcadm.sh` is in the Keycloak pod at `/opt/keycloak/bin/kcadm.sh`. You may also use the Admin Console through `kubectl -n users-demo port-forward svc/keycloak 8080:8080`.
