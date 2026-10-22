# Model Access With Roles, Composite Roles And Groups

A user signs in, gets an access token, and calls the inventory API. The API answers `403 Forbidden`. The token is valid, the user is the right one, and still the API refuses. The API checks one thing in the token, the list of roles, and the role it needs is not there.

A **role** in Keycloak is a named permission, such as `stock-write`, that you give to users. An **access token** is the token a client sends to an API; Keycloak writes the user's roles into it, and the API reads them there. So every access decision starts with one question: which roles end up in the token, and where did each one come from?

This module answers that question from the bottom up. Keep one sentence in mind: **a role reaches a token only if it is mapped to the user, directly or through a composite role or a group, and only if the client's scope lets it through.** Each part adds one link in that chain.

The module has three parts. **Realm Roles And Client Roles** shows the two kinds of role and how a direct mapping reaches a token. **Composite Roles And Default Roles** shows how one role can contain others, and which roles every new user gets. **Group Role Mappings And Roles In Tokens** shows how groups give roles to their members, and how the client scope `roles` writes them into the token; a graded lab follows it.

## Learning objectives

After this module you can:

- Create realm roles and client roles, and explain when to use each.
- Map a role to a user and read it in the access token.
- Build a composite role and read its contents.
- Explain what `default-roles-<realm>` does for new and existing users.
- Map roles to a group, and explain how members and subgroups inherit them.
- Tell a user's direct role mappings from their effective roles.
- Explain how the client scope `roles` fills the `realm_access` and `resource_access` claims.

## Before you start

You need Kubernetes basics and the commands `kubectl get` and `kubectl exec`. You should know how to request a token from a realm's token endpoint and how a JSON Web Token (JWT) is built: three Base64URL parts, of which the middle one holds the claims. This module uses the password grant to get tokens from the terminal; OAuth 2.1 drops that grant, and a real application uses the authorization code flow.

Your playground is a single-node `kind` cluster with **Keycloak 26.8.1** in development mode. The namespace **`roles-demo`** runs these workloads:

| Workload | What it is |
| --- | --- |
| `keycloak` | One Keycloak pod behind the Service `keycloak` on port `8080` |
| `tester` | A client pod with `curl` and `jq`. Every token request in this module is sent from here |

Keycloak holds the realm `inventory` with the users `alice` (password `alice-password`) and `bob` (password `bob-password`), the public client `inventory-cli`, and the client `inventory-api`, which defines the client roles `stock-read` and `stock-write`. The administrator of the `master` realm is `admin` with the password `admin`; these are lab-only credentials.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
