# Federate Users From An LDAP Directory

The company directory already holds every employee: their username, their name, their email address and their password. The inventory application should let those people sign in through Keycloak. Creating every employee a second time in Keycloak would mean two passwords per person and two places to remove someone who leaves.

**User federation** lets Keycloak read users from an outside store instead of its own database. The most common store is an **LDAP** directory: a server that speaks the Lightweight Directory Access Protocol, which reads and writes a tree of users and groups. Microsoft Active Directory speaks LDAP too.

This module connects the realm `inventory` to an OpenLDAP server. Keep one sentence in mind: **with federation, the directory stays the source of truth, and Keycloak checks passwords against it.** Each part shows one side of that link.

The module has three parts. **LDAP Federation And The User Storage SPI** explains how an LDAP directory is organised and how Keycloak plugs it in. **Connecting Keycloak To OpenLDAP** creates the provider and signs a directory user in; a graded lab follows it. **Edit Modes, Mappers And Synchronization** covers who may change what, how attributes and groups are copied, and when Keycloak reads the directory.

## Learning objectives

After this module you can:

- Read an LDAP entry and explain a distinguished name (DN), a base DN and a bind.
- Explain what the User Storage SPI is and where the LDAP provider fits in.
- Create a read-only LDAP provider with `kcadm.sh` and synchronize its users.
- Prove the federation with a token for a user whose password lives only in LDAP.
- Explain the edit modes `READ_ONLY`, `WRITABLE` and `UNSYNCED`.
- Add a group mapper and synchronize LDAP groups into Keycloak.

## Before you start

You need Kubernetes basics and the commands `kubectl get` and `kubectl exec`. You should know what a realm, a user and a group are in Keycloak, and how to request a token with the password grant; this module uses it from the terminal, OAuth 2.1 drops it, and a real application uses the authorization code flow.

Your playground is a single-node `kind` cluster with **Keycloak 26.8.1** in development mode. The namespace **`ldap-demo`** runs these workloads:

| Workload | What it is |
| --- | --- |
| `keycloak` | One Keycloak pod behind the Service `keycloak` on port `8080` |
| `openldap` | OpenLDAP behind the Service `openldap` on port `389`, base DN `dc=example,dc=org` |
| `tester` | A client pod with `curl` and `jq`. Every token request in this module is sent from here |

OpenLDAP holds the users `ldap-ana` and `ldap-ben` (password `ldap-password`) under `ou=people,dc=example,dc=org`, and the group `warehouse`, with `ldap-ana` as its member, under `ou=groups,dc=example,dc=org`. Its administrator is `cn=admin,dc=example,dc=org` with the password `ldap-admin-password`. Keycloak holds the realm `inventory` with the client `inventory-cli` and the user `alice`, and no user federation yet. The administrator of the `master` realm is `admin` with the password `admin`. All of these are lab-only credentials.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
