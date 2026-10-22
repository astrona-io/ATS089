# Prerequisites

Before starting this lab you should be able to:

- Explain what LDAP user federation does.
- Create and read components with `kcadm.sh`, or use the User federation page of the Admin Console.
- Request a token with the password grant from a realm's token endpoint with `curl`.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Keycloak 26.8.1** in development mode in the namespace **`ldap-demo`**, behind the Service `keycloak` on port `8080`.
- **OpenLDAP** behind the Service `openldap` on port `389`, with the base DN `dc=example,dc=org`. Its administrator is `cn=admin,dc=example,dc=org` with the password `ldap-admin-password` (lab-only credentials).
- A `tester` pod with `curl` and `jq`.
- The realm `inventory` with the client `inventory-cli` and the user `alice`. OpenLDAP holds the users `ldap-ana` and `ldap-ben` (password `ldap-password`) in `ou=people,dc=example,dc=org`. The administrator of the `master` realm is `admin` with the password `admin` (lab-only credentials).

Nothing the task asks you to create has been created for you.

## Working rules

- Everything is graded on the **final state** of Keycloak and the cluster, so run your checks again at the end and leave the fix in place.
- Change one setting at a time and test again. A second change you are not sure about makes the first one impossible to check.
- `kubectl`, `curl` and `jq` are available, and `kcadm.sh` is in the Keycloak pod at `/opt/keycloak/bin/kcadm.sh`. You may also use the Admin Console through `kubectl -n ldap-demo port-forward svc/keycloak 8080:8080`.
