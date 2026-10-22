# Overview: Federate Users From An LDAP Directory (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, deploys Keycloak and an OpenLDAP server with two users and one group, creates a realm, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- Namespace **`ldap-demo`** with these workloads:

  | Workload | What it is |
  | --- | --- |
  | `keycloak` | One Keycloak 26.8.1 pod in development mode, behind the Service `keycloak` on port `8080` |
  | `openldap` | OpenLDAP behind the Service `openldap` on port `389`, base DN `dc=example,dc=org` |
  | `tester` | Client pod with `curl` and `jq`; send token requests from here |

- In OpenLDAP:

  | Entry | What it is |
  | --- | --- |
  | `uid=ldap-ana,ou=people,dc=example,dc=org` | User `ldap-ana`, password `ldap-password`, member of `warehouse` |
  | `uid=ldap-ben,ou=people,dc=example,dc=org` | User `ldap-ben`, password `ldap-password` |
  | `cn=warehouse,ou=groups,dc=example,dc=org` | Group (`groupOfNames`) with `ldap-ana` as its member |
  | `cn=admin,dc=example,dc=org` | The directory administrator, password `ldap-admin-password` |

- In Keycloak, the realm **`inventory`** with the client `inventory-cli` and the user `alice`, and no user federation.
- The administrator of the `master` realm is `admin` with the password `admin`. All of these are lab-only credentials.

## Helpers

Paste these once in each new terminal. `kcadm` runs Keycloak's administration command-line tool inside the Keycloak pod. `ldap_search` runs `ldapsearch` inside the OpenLDAP pod as the directory administrator. `get_user_token` prints the response of the password grant; OAuth 2.1 drops that grant, and it is used here only for testing.

```sh
NAMESPACE=ldap-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
ldap_search() {
  kubectl -n "$NAMESPACE" exec deploy/openldap -- ldapsearch -x -LLL -H ldap://localhost \
    -D cn=admin,dc=example,dc=org -w ldap-admin-password -b "$1" "${2:-(objectClass=*)}"
}
get_user_token() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- curl -s \
    http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=password -d client_id=inventory-cli -d username="$1" -d password="$2"
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
```

To use the Admin Console, run `kubectl -n ldap-demo port-forward svc/keycloak 8080:8080` and open `http://localhost:8080/admin/`. The page **User federation** has buttons to test the connection and the bind before you save a provider.

## Practice tasks

- Create the LDAP provider with import off, and see whether `ldap-ana` still gets a token and whether she shows up in the user list.
- Set the users DN to `dc=example,dc=org` and compare a search scope of one level (`1`) with subtree (`2`).
- Change the edit mode to `UNSYNCED`, change `ldap-ana`'s last name in Keycloak, and compare it with `ldap_search`.
- Add a `role-ldap-mapper` that turns the LDAP group `warehouse` into a realm role instead of a group.
- Add a user to the LDAP group by hand with `ldapmodify` in the OpenLDAP pod, and synchronize the groups again.
