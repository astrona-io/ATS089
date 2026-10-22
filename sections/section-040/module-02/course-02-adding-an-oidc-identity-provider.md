# Adding An OpenID Connect Identity Provider

The partner realm is ready and its client accepts the broker endpoint. What is missing is the other half: the realm `inventory` must know the partner as an identity provider, with its endpoints, the client it uses and a rule for what brokered users get. This part adds that with `kcadm.sh`, checks it from the sign-in page, and lets you try a full brokered sign-in in a browser.

## Adding the identity provider

An identity provider in a realm has an **alias**, which appears in the broker endpoint, a `providerId` (`oidc` for any OpenID Connect provider), and a `config` map with the provider's endpoints and the client credentials. All endpoints use `http://localhost:8080`, the address that both your browser (through a port-forward) and the Keycloak pod reach.

Paste the helper for this part. `kcadm` runs Keycloak's administration command-line tool inside the Keycloak pod:

<!-- astrona:playground:renew -->

```sh
NAMESPACE=broker-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
```

Create the identity provider `partner` in `inventory`:

```sh
kcadm create identity-provider/instances -r inventory -s alias=partner -s providerId=oidc \
  -s enabled=true -s displayName=Partner -s firstBrokerLoginFlowAlias="first broker login" \
  -s config.issuer=http://localhost:8080/realms/partner \
  -s config.authorizationUrl=http://localhost:8080/realms/partner/protocol/openid-connect/auth \
  -s config.tokenUrl=http://localhost:8080/realms/partner/protocol/openid-connect/token \
  -s config.userInfoUrl=http://localhost:8080/realms/partner/protocol/openid-connect/userinfo \
  -s config.jwksUrl=http://localhost:8080/realms/partner/protocol/openid-connect/certs \
  -s config.useJwksUrl=true -s config.validateSignature=true \
  -s config.clientId=inventory-broker -s config.clientSecret=inventory-broker-secret \
  -s config.clientAuthMethod=client_secret_post -s config.defaultScope="openid profile email" \
  -s config.syncMode=IMPORT
```

The settings fall into three groups. `issuer`, `authorizationUrl`, `tokenUrl`, `userInfoUrl` and `jwksUrl` say where the partner's endpoints are and who must have signed its tokens. `clientId`, `clientSecret` and `clientAuthMethod` say how `inventory` proves who it is to `partner`. `validateSignature` with `useJwksUrl` makes Keycloak check the signature of every ID token against the partner's public keys.

Read the provider back. Keycloak shows the client secret masked, never in clear text:

```sh
kcadm get identity-provider/instances/partner -r inventory
```

## Giving brokered users a role

Partner staff should get the realm role `partner-user`, so the application can tell them apart from employees. A **Hardcoded Role** mapper (`hardcoded-role-idp-mapper`) gives one role to every user who arrives through the provider:

```sh
kcadm create identity-provider/instances/partner/mappers -r inventory \
  -s name=partner-user-role -s identityProviderAlias=partner \
  -s identityProviderMapper=hardcoded-role-idp-mapper \
  -s config.role=partner-user -s config.syncMode=INHERIT
kcadm get identity-provider/instances/partner/mappers -r inventory --fields name,identityProviderMapper,config
```

The mapper's `syncMode` `INHERIT` means it follows the provider's sync mode.

## Checking the sign-in page

An enabled identity provider shows up as a button on the realm's sign-in page. Load the page from the `tester` pod for the client `inventory-web` and look for the link to the broker:

```sh
kubectl -n "$NAMESPACE" exec deploy/tester -- curl -s \
  'http://keycloak:8080/realms/inventory/protocol/openid-connect/auth?client_id=inventory-web&response_type=code&scope=openid&redirect_uri=http%3A%2F%2Fkeycloak%3A8080%2Fcallback' \
  | grep -o '/realms/inventory/broker/partner/login[^"]*' | head -1
```

The command prints a path that starts with `/realms/inventory/broker/partner/login`. That is the button's target: it starts the brokered sign-in with `partner`.

## A full brokered sign-in in a browser

To see every step, run `kubectl -n broker-demo port-forward svc/keycloak 8080:8080` in a second terminal and open `http://localhost:8080/realms/inventory/account/` in a private browser window. Click **Partner**, sign in as `pat` with `pat-password`, and Keycloak runs the first broker login flow, which may ask `pat` to review the profile. You then land in the account console of `inventory`, signed in as a new local user linked to `partner`. Back in the terminal, read the user and the link:

```sh
PAT_ID="$(kcadm get users -r inventory -q username=pat -q exact=true --fields id --format csv --noquotes | tr -d '\r')"
kcadm get "users/$PAT_ID/federated-identity" -r inventory
kcadm get-roles -r inventory --uusername pat
```

The first command lists one link, to the identity provider `partner`, with `pat`'s user ID in that realm. The second lists `partner-user` next to the default roles: the mapper gave it at the first sign-in.

You can now add an OpenID Connect identity provider, give its users a role, check it from the sign-in page, and follow a full brokered sign-in to the linked local user. Adding GitHub or Google works the same way, with their endpoints and the credentials of an application you register with them.

## Your mission: Broker Sign-In From A Partner Realm

You can now connect two realms with identity brokering, from the client in the external provider to the mapper in the broker. The graded lab gives you both realms without the link, and asks you to register the broker's client in `partner`, add `partner` to `inventory` with its role mapper, and make it appear on the sign-in page.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-089-playground-040-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS089.git -c sections/section-040/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-040/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-089-lab-040-02
astrona start ats-089-playground-040-02
```

## Common pitfalls

> [!WARNING]
> - **Mismatched issuer.** The `issuer` setting must equal the `iss` claim of the partner's tokens, which follows the address Keycloak was reached at. Use one address for every endpoint.
> - **Turning off signature validation to make it work.** Keycloak then accepts any token that looks right. Fix the JWKS URL instead.
> - **A public client in the external provider.** The broker exchanges the code with a client secret, so the client there must be confidential.
> - **Forgetting the redirect URI after renaming the alias.** The broker endpoint contains the alias, so the external client's redirect URI must change with it.
