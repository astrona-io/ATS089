# Manage Users Through Their Whole Lifecycle

A user in the realm `inventory` types the right password, and the token endpoint still refuses. The response says `invalid_grant` and gives one short description. Nothing in the response names the setting that caused it, and three different settings can produce the same kind of refusal.

A **user** in Keycloak is an account in one realm. A **realm** is a space in Keycloak that holds its own users, clients, roles, groups and settings. A user has a username, attributes such as an email address, credentials such as a password, and a state: enabled or disabled, with or without tasks still to do.

This module follows a user through their whole life in a realm. Keep one sentence in mind: **a correct password is not enough; the account must also be enabled, complete and free of pending tasks.** Each part looks at one of those conditions and shows how to read it and fix it from the terminal.

The module has three parts. **Users And The Declarative User Profile** explains the realm's rules for user attributes and why a missing last name blocks a user. **Credentials, Temporary Passwords And Required Actions** covers passwords and the tasks Keycloak can put between a user and their token, and a graded lab follows it. **Groups, Disabling Users And Impersonation** covers groups, ending a user's access without deleting them, and signing in as another user to see what they see.

## Learning objectives

After this module you can:

- Read and create users with `kcadm.sh`, and explain what the user profile requires and of whom.
- Explain why an incomplete profile stops a user from finishing a sign-in.
- Set a permanent or a temporary password, and read a user's required actions.
- Find why a user cannot get a token from the token endpoint's error and the user's settings.
- Add users to a group and remove them.
- Disable a user and end all of their sessions.
- Explain what administrator impersonation does and which role allows it.

## Before you start

You need Kubernetes basics: namespaces, Deployments, Services, and the commands `kubectl get` and `kubectl exec`. You should know that a client gets tokens from a realm's token endpoint. This module uses the password grant to get a token from the terminal; OAuth 2.1 drops that grant, and a real application uses the authorization code flow.

Your playground is a single-node `kind` cluster with **Keycloak 26.8.1** in development mode. The namespace **`users-demo`** runs these workloads:

| Workload | What it is |
| --- | --- |
| `keycloak` | One Keycloak pod behind the Service `keycloak` on port `8080`. Health checks answer on port `9000` |
| `tester` | A client pod with `curl` and `jq`. Every token request in this module is sent from here |

Keycloak holds the realm `inventory` with the client `inventory-cli`, the users `alice` (password `alice-password`) and `bob` (password `bob-password`), and the group `warehouse`, which has `alice` as a member. The administrator of the `master` realm is `admin` with the password `admin`. These are lab-only credentials; never use them on a real server.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
