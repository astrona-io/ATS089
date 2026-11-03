# SAML Identity Providers

Large organisations often run an identity provider that speaks **SAML 2.0**, an XML-based protocol, instead of OpenID Connect. Keycloak can broker to it. The idea is the same as before: the user is sent away, signs in and returns with proof. The language of that proof is different, so the settings and the debugging are different too.

## What differs from OpenID Connect

In SAML, Keycloak is the **service provider** (SP) and the other side is the **identity provider** (IdP). They exchange XML messages: an authentication request goes to the IdP and a signed **assertion** comes back. The assertion carries a **NameID**, the identifier of the user, and optional attributes. Each side has an **entity ID**, a unique name, and a metadata document that lists its endpoints and keys.

## Adding a SAML provider

The provider type is `saml`. The essential setting is the URL of the single sign-on service of the IdP. Paste the helper and add one. The URL is a placeholder:

<!-- astrona:playground:renew -->

```sh
NAMESPACE=broker-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
kcadm create identity-provider/instances -r inventory -s alias=partner-saml -s providerId=saml \
  -s enabled=true -s displayName="Partner SAML" \
  -s config.singleSignOnServiceUrl=https://idp.partner.example/sso \
  -s config.nameIDPolicyFormat=urn:oasis:names:tc:SAML:2.0:nameid-format:persistent \
  -s config.principalType=SUBJECT -s config.postBindingResponse=true \
  -s config.postBindingAuthnRequest=true -s config.validateSignature=false
kcadm get identity-provider/instances/partner-saml -r inventory --fields alias,providerId,config
```

`nameIDPolicyFormat` says which kind of identifier Keycloak asks for. `persistent` is a stable pseudonym that does not change when the email changes. `principalType=SUBJECT` takes the username from the NameID. The two `postBinding` settings choose the HTTP POST way of sending messages. `validateSignature=false` is acceptable only in a lab: in production you turn it on and give the IdP's signing certificate, or the IdP's metadata URL so the key is read for you.

## Giving the IdP the metadata of Keycloak

The IdP must know Keycloak's endpoints and signing key. Keycloak publishes them as an XML document, the **SP descriptor**. Read it from the `tester` pod:

```sh
kubectl -n "$NAMESPACE" exec deploy/tester -- curl -s \
  http://keycloak:8080/realms/inventory/broker/partner-saml/endpoint/descriptor | head -c 400
```

The output starts with an `EntityDescriptor` element. Give this document, or its URL, to the administrator of the IdP. In the reverse direction, `identity-provider/import-config` reads the IdP's metadata and returns the settings to use, so you do not type the URLs by hand.

## Mapping attributes

A SAML provider carries user data as attributes in the assertion. An identity provider mapper of type **Attribute Importer** copies an attribute, by its name, into a user attribute. Add it the same way as the OIDC mapper from the previous part, with the provider alias `partner-saml`.

## Debugging

A failed SAML sign-in is hard to read in the browser, because the messages are encoded. Keycloak writes the reason in the server log and in the user event, so turn on events and read the `error`. The most common causes are a wrong entity ID, a clock difference between the servers that makes the assertion look expired, and a signature that cannot be verified with the key you gave.

## Common pitfalls

> [!WARNING]
> - **Leaving `validateSignature` off outside a lab.** Anyone could forge an assertion.
> - **Using `transient` or `email` NameID by habit.** Pick the format the IdP supports and that stays stable.
> - **Forgetting to send the SP descriptor to the IdP.** The IdP will refuse messages from an unknown entity.
> - **Servers with different clocks.** Assertions have a validity window.
