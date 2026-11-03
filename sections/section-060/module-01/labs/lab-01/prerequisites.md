# Prerequisites

Before starting this lab you should be able to:

- Run `kcadm.sh` commands in the Keycloak pod and read the JSON they print.
- Read a realm's settings with `kcadm get realms/<realm>`.
- Create an organization with `kcadm create organizations`.

## What the environment gives you

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Keycloak 26.8.1** in development mode in the namespace **`orgs-demo`**, behind the Service `keycloak` on port `8080`.
- A `tester` pod with `curl` and `jq`.
- The administrator of the `master` realm is `admin` with the password `admin` (lab-only credentials).

## Working rules

- Everything is graded on the **final state** of Keycloak, so check your work again at the end and leave the change in place.
- Change one setting at a time and read it back.
- `kubectl`, `curl` and `jq` are available, and `kcadm.sh` is in the Keycloak pod at `/opt/keycloak/bin/kcadm.sh`.
