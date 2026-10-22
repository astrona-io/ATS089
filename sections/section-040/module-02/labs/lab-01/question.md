# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Federation and brokering

## Scenario

The partner company's staff live in the realm `partner`. They must be able to sign in to the realm `inventory` through `partner`, without a second password, and the inventory application must recognise them by the realm role `partner-user`. Both realms run in the same Keycloak in the namespace `broker-demo`.

The browser reaches Keycloak through `kubectl -n broker-demo port-forward svc/keycloak 8080:8080`, and the Keycloak pod reaches itself at the same address, so every URL of the `partner` realm in this task starts with `http://localhost:8080/realms/partner`.

## Your task

1. In the realm `partner`, create the confidential client `inventory-broker` with the client secret `inventory-broker-secret`, the standard flow on, and the redirect URI `http://localhost:8080/realms/inventory/broker/partner/endpoint`.
2. In the realm `inventory`, add an OpenID Connect identity provider with the alias `partner`. It uses the client `inventory-broker` and its secret, the issuer `http://localhost:8080/realms/partner`, the partner's authorization, token, user info and JWKS endpoints, and the first broker login flow `first broker login`. Keep signature validation on.
3. Add a mapper to the identity provider that gives every brokered user the realm role `partner-user`.
4. Check that the sign-in page of `inventory` for the client `inventory-web` offers `partner`.

A full sign-in through `partner` needs a browser. You may try it with the user `pat` (password `pat-password`); the grader checks the configuration and the sign-in page.

## Constraints

- Do not change `pat` or the realm `partner` beyond the new client.
- Do not turn off signature validation.
- Do not create a local user `pat` in `inventory`.

## Done when

- `partner` has the confidential client `inventory-broker` with the standard flow, the broker endpoint as its redirect URI and the secret `inventory-broker-secret`.
- `inventory` has the enabled `oidc` identity provider `partner` with the issuer, authorization and token URLs of `partner`, the client ID `inventory-broker` and the flow `first broker login`.
- The identity provider has a Hardcoded Role mapper for `partner-user`.
- The `inventory` sign-in page links to `/realms/inventory/broker/partner/login`.
