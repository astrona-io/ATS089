# Social Identity Providers

Many users prefer to sign in with an account they already have at GitHub or Google. These are **social identity providers**. For Keycloak they are identity providers like the partner realm, with two differences: Keycloak ships a dedicated provider type for each, and the provider's own site hosts the endpoints, so you only enter the client credentials.

## Provider types

A social provider has its own `providerId`, for example `github`, `google`, `gitlab` or `facebook`. The type fixes the endpoints, so the `config` needs only the credentials and the scope. Before you add the provider, you register Keycloak as an application at the social site. The site asks for a redirect URI, and gives you a client ID and a client secret. The redirect URI is the broker endpoint of your provider:

```text
http://localhost:8080/realms/inventory/broker/github/endpoint
```

It has the form `<server>/realms/<realm>/broker/<alias>/endpoint`, so the alias you choose is part of it. A mismatch makes the social site refuse the sign-in.

## Adding GitHub

Paste the helper. The client ID and secret below are placeholders; a real sign-in needs values from a GitHub OAuth application:

<!-- astrona:playground:renew -->

```sh
NAMESPACE=broker-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
kcadm create identity-provider/instances -r inventory -s alias=github -s providerId=github \
  -s enabled=true -s config.clientId=placeholder-client-id -s config.clientSecret=placeholder-secret \
  -s config.defaultScope=user:email
kcadm get identity-provider/instances/github -r inventory --fields alias,providerId,enabled,config
```

The read shows the provider with the secret masked. The sign-in page of the realm now has a **GitHub** button, because an enabled provider appears on it. The button works only with real credentials.

## Choices that matter

**Trust of the email.** A social site may return an email address that the user never verified. Keycloak's first broker login flow can link the account to an existing user with the same email. If you let it link without a check, a person could take over an account by registering that email at the social site. Keep the verification step of the flow on unless the provider is one you trust to verify addresses.

**Scopes.** Ask only for what you need. For GitHub, `user:email` gives the email; adding wider scopes asks the user for more than the realm uses.

**Sync mode.** `IMPORT` copies the profile once at the first sign-in. `FORCE` overwrites it at every sign-in, so changes made in Keycloak are lost. Use `FORCE` only when the social profile is the source of truth.

**Hiding the button.** The setting `hideOnLogin` keeps the provider off the sign-in page but leaves it usable by a direct link, for example for staff only.

Update a setting with `kcadm update`:

```sh
kcadm update identity-provider/instances/github -r inventory -s config.syncMode=FORCE
```

## Common pitfalls

> [!WARNING]
> - **A redirect URI that does not match the alias.** The social site refuses the request.
> - **Committing a real client secret to a repository.** Keep it in a Secret, not in a script.
> - **Linking accounts by unverified email.** Keep the verification step of the first broker login flow.
> - **Asking for wide scopes.** Each scope is shown to the user.
