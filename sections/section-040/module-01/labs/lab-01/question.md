# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Federation and brokering

## Scenario

The company directory is an OpenLDAP server in the namespace `ldap-demo`. Its users must sign in to the realm `inventory` with their directory passwords. The directory team owns every change to user data, so Keycloak must never write to the directory.

| Setting | Value |
| --- | --- |
| LDAP server | `ldap://openldap:389` |
| Bind DN | `cn=admin,dc=example,dc=org` |
| Bind password | `ldap-admin-password` |
| Users DN | `ou=people,dc=example,dc=org` |
| Username and RDN attribute | `uid` |
| UUID attribute | `entryUUID` |
| User object classes | `inetOrgPerson`, `organizationalPerson` |

The directory holds `ldap-ana` and `ldap-ben`, both with the password `ldap-password`.

## Your task

In the realm `inventory`:

1. Add an LDAP user federation provider named `openldap` with the settings in the table, in the edit mode `READ_ONLY`, with import on.
2. Bring both directory users into Keycloak, linked to the provider.
3. Prove it: `ldap-ana` must get an access token from the client `inventory-cli` with the password grant and her LDAP password.

The password grant is used here only so you can test from a terminal.

## Constraints

- The provider must be `READ_ONLY`. Do not use `WRITABLE` or `UNSYNCED`.
- Do not create `ldap-ana` or `ldap-ben` as local Keycloak users.
- Do not change the OpenLDAP server or its data.

## Done when

- The realm has an LDAP provider named `openldap`, `READ_ONLY`, with import on, for `ldap://openldap:389` and `ou=people,dc=example,dc=org`.
- `ldap-ana` gets an access token with `ldap-password`, and its `preferred_username` is `ldap-ana`.
- `ldap-ana` and `ldap-ben` exist in Keycloak with `federationLink` set to the provider.
