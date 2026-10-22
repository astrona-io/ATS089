# Sign Users In Through Another Identity Provider

A partner company runs its own Keycloak and its own user accounts. Its staff need to use the inventory application, but the partner will not export its users, and its staff should not get a second password. The realm `inventory` has no way to check a partner employee's password, and it should not have one.

**Identity brokering** solves this. Keycloak sends the user to another identity provider to sign in, receives a signed answer, and then creates or links a local user for that person. An **identity provider (IdP)** is a service that checks who a user is and tells applications the result. Social login, such as "Sign in with GitHub", is identity brokering with a public identity provider.

This module makes a second realm, `partner`, the identity provider for `inventory`. Keep one sentence in mind: **with brokering, the other provider checks the password, and Keycloak trusts its signed token.** That is the difference from federation, where Keycloak checks the password itself.

The module has two parts. **Identity Brokering And Social Login** explains the redirect flow, the first broker login flow and the choices you make for every provider. **Adding An OpenID Connect Identity Provider** registers `inventory` as a client of `partner`, adds `partner` as an identity provider with a mapper, and checks the result; a graded lab follows it.

## Learning objectives

After this module you can:

- Explain identity brokering and how it differs from user federation.
- Follow the redirects of a brokered sign-in and name the broker endpoint.
- Explain the first broker login flow and the sync modes of an identity provider.
- Register the broker as a confidential client in the external provider.
- Add an OpenID Connect identity provider to a realm with `kcadm.sh`.
- Add a mapper that gives every brokered user a realm role.

## Before you start

You need Kubernetes basics and the commands `kubectl get`, `kubectl exec` and `kubectl port-forward`. You should know the authorization code flow: the browser is sent to the identity provider, comes back with a code, and the client exchanges the code for tokens at the token endpoint. A web browser on your machine lets you try a full brokered sign-in.

Your playground is a single-node `kind` cluster with **Keycloak 26.8.1** in development mode. The namespace **`broker-demo`** runs these workloads:

| Workload | What it is |
| --- | --- |
| `keycloak` | One Keycloak pod behind the Service `keycloak` on port `8080` |
| `tester` | A client pod with `curl` and `jq` |

Keycloak holds two realms. `inventory` has the user `alice`, the clients `inventory-cli` and `inventory-web`, and the realm role `partner-user`. `partner` has the user `pat` (password `pat-password`) and the confidential client `inventory-broker` (secret `inventory-broker-secret`), which `inventory` will use to talk to `partner`. Both realms run in the same Keycloak here; in real life the partner's identity provider runs elsewhere. The administrator of the `master` realm is `admin` with the password `admin`. All of these are lab-only credentials.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
