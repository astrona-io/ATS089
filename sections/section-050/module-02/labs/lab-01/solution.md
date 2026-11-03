# Solution: Set Session And Token Limits And Revoke Offline Access

Work the task yourself first. Running `astrona submit -c sections/section-050/module-02/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the realm limits, the lifespan of a token for each client, and the offline sessions of both users.

## Step 1: Set up the helper

```sh
NAMESPACE=sessions-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
```

## Step 2: Set the realm limits

```sh
kcadm update realms/inventory -s ssoSessionIdleTimeout=900 -s ssoSessionMaxLifespan=28800 \
  -s accessTokenLifespan=120 -s offlineSessionIdleTimeout=604800 -s offlineSessionMaxLifespanEnabled=true
```

## Step 3: Give the batch client a longer token

The attribute name contains dots, so it is quoted:

```sh
BATCH=$(kcadm get clients -r inventory -q clientId=inventory-batch --fields id --format csv --noquotes | tr -d '\r')
kcadm update "clients/$BATCH" -r inventory -s 'attributes."access.token.lifespan"=600'
```

## Step 4: Revoke the offline session of bob

```sh
BOB=$(kcadm get users -r inventory -q username=bob -q exact=true --fields id --format csv --noquotes | tr -d '\r')
CLI=$(kcadm get clients -r inventory -q clientId=inventory-cli --fields id --format csv --noquotes | tr -d '\r')
for session in $(kcadm get "users/$BOB/offline-sessions/$CLI" -r inventory --fields id --format csv --noquotes | tr -d '\r'); do
  kcadm delete "sessions/$session?isOffline=true" -r inventory
done
```

## Step 5: Check the result

```sh
kcadm get realms/inventory --fields ssoSessionIdleTimeout,ssoSessionMaxLifespan,accessTokenLifespan,offlineSessionIdleTimeout,offlineSessionMaxLifespanEnabled
kcadm get "users/$BOB/offline-sessions/$CLI" -r inventory
```

The last command prints an empty list.

## Step 6: Submit

```sh
astrona submit -c sections/section-050/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| `logout-all` | ends the online sessions of everyone and still leaves the offline sessions |
| `users/<id>/logout` for bob | ends his online sessions, not his offline session |
| Delete `bob` | removes the account, but the task asks to keep it |
| Delete the session without `isOffline=true` | Keycloak looks for an online session with that id and removes nothing |
