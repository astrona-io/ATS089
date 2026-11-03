# Record And Read Events And Admin Events

A user says they could not sign in at nine o'clock. An administrator asks who changed a role yesterday. A security team asks how many wrong passwords were tried for one account. Keycloak can answer all three, but only when the realm has been told to record events before the question is asked. Nothing is recorded by default, so a realm that never turned events on has no history to read.

An **event** is a record Keycloak writes when something happens in a realm. A **user event** records something a user or a client did, such as a sign-in or a token refresh. An **admin event** records a change an administrator made through the Admin API or the Admin Console, such as creating a user. This module teaches how to turn each kind on, how to read them and how to find the cause of a failure in them. Keep one sentence in mind: **events are recorded from the moment you turn them on, never before.**

The module has four parts. **User Events** covers what is recorded and for how long. **Admin Events** covers recording changes made by administrators. **Finding A Failed Sign-In** covers reading errors and matching them with a request, and a graded lab follows it. **Retention, Listeners And Server Logs** covers where events go besides the database.

## Learning objectives

After this module you can:

- Turn on user events, choose the event types and set how long they are kept.
- Turn on admin events, with and without the representation of the changed object.
- Read events with filters for type, user, client and date.
- Find the cause of a failed sign-in in the `error` field of an event.
- Explain what event listeners are and where the `jboss-logging` listener writes.

## Before you start

You need Kubernetes basics and the idea that a client gets tokens from a realm's token endpoint. This module uses the password grant to get tokens from the terminal; OAuth 2.1 drops that grant, and a real application uses the authorization code flow.

Your playground is a single-node `kind` cluster with **Keycloak 26.8.1** in development mode. The namespace **`events-demo`** runs these workloads:

| Workload | What it is |
| --- | --- |
| `keycloak` | One Keycloak pod behind the Service `keycloak` on port `8080` |
| `tester` | A client pod with `curl` and `jq`. Every token request is sent from here |

Keycloak holds the realm `inventory` with the user `alice` (password `alice-password`) and the public client `inventory-cli` with direct access grants on. Events are off. The administrator of the `master` realm is `admin` with the password `admin`. These are lab-only credentials.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
