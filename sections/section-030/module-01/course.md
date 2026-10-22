# Control How Users Sign In With Flows, OTP And Passkeys

A security review asks for two things: stronger passwords for everyone, and a second factor for the people who administer stock. Both are realm settings in Keycloak, but the second one means changing the steps of the sign-in itself. A careless change to those steps can lock every user out of the realm at once.

An **authentication flow** is an ordered tree of steps that Keycloak runs when a user signs in. Each step is an **execution**: an authenticator such as the password form, a condition, or a nested subflow. Each execution has a requirement that says whether it must succeed, may succeed, or runs only under a condition.

This module shows you how to read and change flows safely. Keep one sentence in mind: **never edit the flow users depend on; copy it, change the copy, then bind the copy.** That way the original stays as a known-good fallback.

The module has three parts. **Authentication Flows, Executions And Requirements** reads the built-in browser flow and explains how flows are bound to a realm. **Password Policy And One-Time Passwords** sets a password policy and builds a flow that asks for a one-time password only from users with the role `stock-admin`; a graded lab follows it. **WebAuthn And Passkeys** prepares the realm for passkeys, the credential that replaces the password.

## Learning objectives

After this module you can:

- Read the executions of a flow and explain each requirement: `REQUIRED`, `ALTERNATIVE`, `CONDITIONAL` and `DISABLED`.
- Read which flow is bound to the browser and to the direct grant, and change a binding.
- Copy a built-in flow and change the copy.
- Set a password policy and prove that it refuses a weak password.
- Read the OTP policy, and require OTP only for users with one realm role.
- Configure the WebAuthn passwordless policy and the required action that registers a passkey.

## Before you start

You need Kubernetes basics and the commands `kubectl get`, `kubectl exec` and `kubectl port-forward`. You should know how to request a token with the password grant; this module uses it from the terminal, OAuth 2.1 drops it, and a real application uses the authorization code flow. A web browser on your machine helps, because a flow's forms are easiest to see there.

Your playground is a single-node `kind` cluster with **Keycloak 26.8.1** in development mode. The namespace **`flows-demo`** runs these workloads:

| Workload | What it is |
| --- | --- |
| `keycloak` | One Keycloak pod behind the Service `keycloak` on port `8080` |
| `tester` | A client pod with `curl` and `jq`. Every token request in this module is sent from here |

Keycloak holds the realm `inventory` with the client `inventory-cli`, the users `alice` (password `alice-password`) and `bob` (password `bob-password`), and the realm role `stock-admin`, which `bob` holds. The administrator of the `master` realm is `admin` with the password `admin`; these are lab-only credentials.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
