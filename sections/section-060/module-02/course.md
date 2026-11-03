# Delegate Administration With Realm-Management Roles

The `admin` of the `master` realm can do everything on a server. Giving that account to a help desk, an auditor or a customer's contact is a risk, because one mistake or one stolen password reaches every realm. Keycloak lets you give a person only the part of the administration that the work needs, inside one realm. This is **delegated administration**.

This module teaches who can administer a realm, which roles carry which rights, how to give a user only some of them and how to prove from the terminal what that user can and cannot do. Keep one sentence in mind: **grant the smallest set of roles that does the job, and test it with the account that receives them.**

The module has four parts. **Who Can Administer A Realm** covers the three kinds of administrator. **The Realm-Management Roles** covers the roles and how to assign them with `kcadm.sh`. **Proving What An Administrator Can Do** covers testing with a real token, and a graded lab follows it. **Fine-Grained Permissions And Limits** covers the policy-based alternative and what roles cannot express.

## Learning objectives

After this module you can:

- Name the three kinds of realm administrator and the realm each can manage.
- Choose realm-management roles for a task and assign them with `kcadm.sh`.
- Test an administrator with a token and read `200`, `400` and `403` answers from the Admin API.
- Explain what fine-grained admin permissions add to roles.

## Before you start

You need `kcadm.sh` basics and the idea of a bearer token. This module uses the password grant on the realm's `admin-cli` client to get tokens from the terminal.

Your playground is a single-node `kind` cluster with **Keycloak 26.8.1** in development mode. The namespace **`admin-delegation-demo`** runs these workloads:

| Workload | What it is |
| --- | --- |
| `keycloak` | One Keycloak pod behind the Service `keycloak` on port `8080` |
| `tester` | A client pod with `curl` and `jq`. Every token and Admin API request is sent from here |

Keycloak holds the realm `inventory` with the users `helpdesk` and `auditor` (passwords `helpdesk-password` and `auditor-password`) and the users `alice` and `bob`. The two administrators have no administration roles yet. The administrator of the `master` realm is `admin` with the password `admin`. These are lab-only credentials.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
