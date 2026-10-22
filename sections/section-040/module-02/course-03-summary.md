# Summary

Identity brokering lets a realm send users to another identity provider to sign in, and trust the signed answer. The other provider checks the password; the broker never sees it. That is the difference from user federation, where Keycloak checks the password against a directory itself.

## What you learned

A brokered sign-in is the authorization code flow with a realm as the client. The browser is sent to the external provider, signs in there, and returns with a code to the broker endpoint, `/realms/<realm>/broker/<alias>/endpoint`. The broker exchanges the code for tokens at the provider's token endpoint and checks the ID token's signature against the provider's public keys. The external provider must know the broker as a confidential client with the broker endpoint as its redirect URI.

The first time a person arrives from a provider, Keycloak runs the first broker login flow, which can ask the user to review their profile and can link the arrival to an existing local user. The sync mode decides whether later sign-ins update the local user: `IMPORT` copies data once, `FORCE` updates it every time. Identity provider mappers copy claims or set data during the sign-in; a Hardcoded Role mapper gives every brokered user one role.

An OpenID Connect identity provider is added with the alias, the provider type `oidc`, the provider's endpoints and issuer, and the broker's client ID and secret. Every endpoint must use an address that both the browser and the Keycloak server can reach, and the issuer must match the tokens. An enabled provider appears as a button on the realm's sign-in page, and a brokered user carries a federated identity that links them to the provider. Social login works the same way with a public provider.

- The external provider checks the password; the broker checks the signature.
- The broker endpoint contains the alias.
- One address for every endpoint, matching the issuer.

<!-- astrona:playground:destroy -->
