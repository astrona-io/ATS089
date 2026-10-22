# Solution: Broker Sign-In From A Partner Realm

Work the task yourself first. Running `astrona submit -c sections/section-040/module-02/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks four things: the client in `partner`, the identity provider in `inventory`, its role mapper, and the link on the sign-in page.

## Step 1: Set up the helper

```sh
NAMESPACE=broker-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
```

## Step 2: Create the broker's client in partner

The broker exchanges the code with a client secret, so the client must be confidential. Its only redirect URI is the broker endpoint, which contains the alias `partner`:

```sh
kcadm create clients -r partner -s clientId=inventory-broker -s enabled=true \
  -s publicClient=false -s secret=inventory-broker-secret \
  -s standardFlowEnabled=true -s directAccessGrantsEnabled=false \
  -s 'redirectUris=["http://localhost:8080/realms/inventory/broker/partner/endpoint"]'
```

## Step 3: Add the identity provider in inventory

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

## Step 4: Add the role mapper

```sh
kcadm create identity-provider/instances/partner/mappers -r inventory \
  -s name=partner-user-role -s identityProviderAlias=partner \
  -s identityProviderMapper=hardcoded-role-idp-mapper \
  -s config.role=partner-user -s config.syncMode=INHERIT
```

## Step 5: Check the sign-in page

```sh
kubectl -n "$NAMESPACE" exec deploy/tester -- curl -s \
  'http://keycloak:8080/realms/inventory/protocol/openid-connect/auth?client_id=inventory-web&response_type=code&scope=openid&redirect_uri=http%3A%2F%2Fkeycloak%3A8080%2Fcallback' \
  | grep -o '/realms/inventory/broker/partner/login[^"]*' | head -1
```

The command prints a path that starts with `/realms/inventory/broker/partner/login`: the page offers `partner`.

## Step 6 (optional): Sign in through partner in a browser

Run `kubectl -n broker-demo port-forward svc/keycloak 8080:8080`, open `http://localhost:8080/realms/inventory/account/` in a private window, click **Partner**, and sign in as `pat` with `pat-password`. After the first broker login flow, you are in the account console of `inventory`. `kcadm get-roles -r inventory --uusername pat` then lists `partner-user`.

## Step 7: Submit

```sh
astrona submit -c sections/section-040/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Make `inventory-broker` a public client | the code exchange with a secret fails, and the grader checks it is confidential |
| Use `http://keycloak:8080` in the endpoints | the browser cannot reach that address, so the redirect to `partner` fails |
| Turn off signature validation | Keycloak accepts unsigned or forged tokens from anyone who can reach the broker endpoint |
| Create a local `pat` in `inventory` | `pat` gets a second password, which is exactly what brokering avoids |
