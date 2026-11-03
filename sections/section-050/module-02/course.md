# Control Sessions, Token Lifespans And Offline Access

A user who signs in once expects to stay signed in for a while, and a security team expects that "a while" has an end. Keycloak answers with two kinds of time limit. Session limits decide how long the user stays signed in. Token lifespans decide how long each token works. A third mechanism, the offline token, lets an application keep access long after the user has left. Each limit is a number in the realm settings, and a wrong number either logs users out too often or keeps access open too long.

A **session** is Keycloak's record that a user signed in. A **token** is the signed document Keycloak gives an application as proof of that sign-in. This module teaches the settings behind both and how to read and end sessions from the terminal. Keep one sentence in mind: **a token works until its own expiry, a refresh token also needs its session, and ending a session does not recall an access token that is already issued.**

The module has four parts. **SSO Session Settings** covers the idle and maximum lifetimes of a session. **Token Lifespans** covers the access token, the codes and the per-client override. **Offline Tokens** covers long-lived access and how to revoke it, and a graded lab follows it. **Administering Sessions** covers listing, counting and ending sessions.

## Learning objectives

After this module you can:

- Set the SSO session idle and maximum lifetimes and explain how remember me changes them.
- Set the access token lifespan for a realm and override it for one client, and prove the value from a token.
- Request an offline token, explain what keeps it alive and revoke it.
- List the sessions of a user and a client, count them and end them.
- Explain why ending a session does not invalidate a token that was already issued.

## Before you start

You need Kubernetes basics and the idea that a client gets tokens from a realm's token endpoint. This module uses the password grant to get tokens from the terminal; OAuth 2.1 drops that grant, and a real application uses the authorization code flow.

Your playground is a single-node `kind` cluster with **Keycloak 26.8.1** in development mode. The namespace **`sessions-demo`** runs these workloads:

| Workload | What it is |
| --- | --- |
| `keycloak` | One Keycloak pod behind the Service `keycloak` on port `8080` |
| `tester` | A client pod with `curl` and `jq`. Every token request is sent from here |

Keycloak holds the realm `inventory` with the users `alice` (password `alice-password`) and `bob` (password `bob-password`), and the public clients `inventory-cli` and `inventory-batch`, both with direct access grants on. The administrator of the `master` realm is `admin` with the password `admin`. These are lab-only credentials.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
