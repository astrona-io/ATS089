# Question

Solve this question on: `terminal`

**Time:** about 35 minutes · **Topic:** Federation and brokering

## Scenario

The realm `inventory` federates users from an OpenLDAP directory through the provider `openldap`. After the directory team rotated passwords and reorganised the tree, no directory user can sign in. The team also expected the LDAP group `warehouse` to show up in Keycloak, and it never has.

What the directory looks like today:

| Setting | Value |
| --- | --- |
| Bind DN and password | `cn=admin,dc=example,dc=org`, `ldap-admin-password` |
| Users | `ldap-ana` and `ldap-ben`, password `ldap-password`, under `ou=people,dc=example,dc=org` |
| Groups | `warehouse` (`groupOfNames`, members as full DNs in `member`), under `ou=groups,dc=example,dc=org`; `ldap-ana` is the only member |

## Your task

In the realm `inventory` and the namespace `federationcapstone-demo`:

1. Find why the directory users cannot sign in. Compare the provider's settings with the directory.
2. Repair the provider `openldap` so that `ldap-ana` and `ldap-ben` get tokens with their LDAP password from the client `inventory-cli`.
3. Make the LDAP group `warehouse` appear in Keycloak with its member, read-only.

The password grant is used here only so you can test from a terminal.

## Constraints

- **Repair the provider that exists.** Do not delete or recreate `openldap`. The grader compares its ID with the one the lab started with.
- Keep the edit mode `READ_ONLY`.
- Do not change the OpenLDAP server or its data, and do not create local Keycloak users for the directory users.
- Do not change the ConfigMap `capstone-baseline`.

## Done when

- `ldap-ana` and `ldap-ben` each get an access token with `ldap-password`.
- `openldap` has its original ID, is `READ_ONLY`, and reads users from `ou=people,dc=example,dc=org`.
- `openldap` has a group mapper for `ou=groups,dc=example,dc=org`.
- In Keycloak, `ldap-ana` is a member of `warehouse` and `ldap-ben` is not.
