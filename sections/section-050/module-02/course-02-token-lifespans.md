# Token Lifespans

A token that never expires is a password that cannot be changed. Keycloak puts an expiry time in every token it signs, and the claim `exp` in the token holds it. This part shows the realm settings that choose that time, the short codes that belong to the browser flows and the way one client can get a different lifespan from the rest of the realm.

## The access token lifespan

An **access token** is the token an application sends to an API to prove who the user is and what the user may do. The realm field `accessTokenLifespan` sets how many seconds it works; the default is 300, which is five minutes. A short lifespan limits the damage when a token leaks. A long one means fewer refreshes. The **refresh token** is the longer-lived token an application exchanges for a new access token, and its lifetime follows the SSO session.

Paste the helper and read the field:

<!-- astrona:playground:renew -->

```sh
NAMESPACE=sessions-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
kcadm get realms/inventory --fields accessTokenLifespan,accessTokenLifespanForImplicitFlow,accessCodeLifespan,accessCodeLifespanUserAction,accessCodeLifespanLogin
```

The other fields are lifespans of codes, not of tokens. `accessCodeLifespan` (60 seconds) is how long the authorization code of the authorization code flow works before the client must exchange it. `accessCodeLifespanUserAction` (300 seconds) is how long a user has to finish an action, such as using a link in an email. `accessCodeLifespanLogin` (1800 seconds) is how long the sign-in page may stay open before Keycloak rejects the submitted form.

## Proving the lifespan from a token

A token states its own lifetime. Define a helper that requests a token for `alice` with a client and prints `exp` minus `iat` (expiry minus issue time) in seconds. The `jq` filter decodes the middle part of the token, which is Base64-encoded JSON:

```sh
token_lifespan() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- curl -s \
    http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=password -d client_id="$1" -d username=alice -d password=alice-password \
    | kubectl -n "$NAMESPACE" exec -i deploy/tester -- jq -r '.access_token' \
    | kubectl -n "$NAMESPACE" exec -i deploy/tester -- jq -R 'split(".")[1] | gsub("-";"+") | gsub("_";"/") | . + ("=" * ((4 - length % 4) % 4)) | @base64d | fromjson | .exp - .iat'
}
token_lifespan inventory-cli
```

The command prints one number: 300 on a new realm. Now shorten it and ask again:

```sh
kcadm update realms/inventory -s accessTokenLifespan=120
token_lifespan inventory-cli
```

The number is now 120. Keycloak, the server that signs the token, used the new realm value for the next token. Tokens issued earlier keep their old expiry, because the expiry is inside the signed token.

## Overriding the lifespan for one client

A batch job may need a longer token than a browser application. Each client can set its own lifespan in the client attribute `access.token.lifespan`. The attribute name contains dots, so quote it in the `kcadm.sh` option:

```sh
CLIENT_ID_UUID=$(kcadm get clients -r inventory -q clientId=inventory-batch --fields id --format csv --noquotes | tr -d '\r')
kcadm update "clients/$CLIENT_ID_UUID" -r inventory -s 'attributes."access.token.lifespan"=600'
token_lifespan inventory-batch
token_lifespan inventory-cli
```

The first command prints 600 and the second prints 120. A client override wins over the realm value for that client only. Keep the SSO idle limit larger than the longest token lifespan, because the refresh token stops working when the session ends.

You can now choose a token lifespan for a realm and for one client, and prove it from the token itself. A token that works for minutes is the normal case. Some applications need access for weeks, which is what offline tokens are for.

## Common pitfalls

> [!WARNING]
> - **Mixing up codes and tokens.** `accessCodeLifespan` is the authorization code. `accessTokenLifespan` is the access token.
> - **Expecting old tokens to shorten.** A token keeps the expiry it was issued with.
> - **Forgetting the quotes around the client attribute.** Without `'attributes."access.token.lifespan"=600'`, the dots split the name into nested fields.
> - **Making a client token longer than the session idle limit.** The application cannot refresh once the session has ended.
