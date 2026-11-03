# Group Users Into Organizations

A realm holds all users of one Keycloak setup. When the users belong to different companies, teams or customers, a flat list of users is hard to work with: you cannot say which users belong to which customer, and you cannot let a customer's staff sign in through that customer's own identity provider. An **organization** is a Keycloak object that groups users of a realm under one name and one alias, and gives them their own domains, attributes and members.

This module teaches how to turn organizations on, how to create them, how to add members and how a token tells an application which organization a user belongs to. Keep one sentence in mind: **an organization is a grouping inside one realm, not a second realm.** Users, clients and roles still live in the realm.

The module has four parts. **Enabling And Creating Organizations** covers the realm switch and the fields of an organization. **Domains And Attributes** covers how an email domain maps to an organization. **Members** covers managed and unmanaged members, and a graded lab follows it. **The Organization Claim** covers the `organization` scope and the token claim.

## Learning objectives

After this module you can:

- Enable organizations in a realm and create an organization with `kcadm.sh`.
- Explain the name, the alias, the domains and the attributes of an organization.
- Add and remove members, and explain managed and unmanaged members.
- Request the `organization` scope and read the `organization` claim of a token.

## Before you start

You need the `kcadm.sh` basics from the earlier sections. You do not need an identity provider for this module.

Your playground is a single-node `kind` cluster with **Keycloak 26.8.1** in development mode. The namespace **`orgs-demo`** runs these workloads:

| Workload | What it is |
| --- | --- |
| `keycloak` | One Keycloak pod behind the Service `keycloak` on port `8080` |
| `tester` | A client pod with `curl` and `jq`. Every token request is sent from here |

Keycloak holds the realm `inventory` with the users `alice` and `bob` (passwords `alice-password` and `bob-password`) and the public client `inventory-cli` with direct access grants on. Organizations are off. The administrator of the `master` realm is `admin` with the password `admin`. These are lab-only credentials.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
