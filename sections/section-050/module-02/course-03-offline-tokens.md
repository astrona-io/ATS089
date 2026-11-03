# Offline Tokens

Some applications need to act for a user when the user is not there: a nightly synchronization, a mobile app that opens a week later, a report that runs at midnight. A normal refresh token stops when the SSO session ends, so these applications need a token that does not depend on the browser session. That token is the offline token.

## What an offline token is

An **offline token** is a refresh token with the type `Offline`. A client gets one when it asks for the scope `offline_access` in the request. Keycloak stores an **offline session** for it in the database, so it survives a restart of the server and the end of the user's SSO session. The user needs the realm role `offline_access`, which the default roles of a realm already include.

Paste the helper and request an offline token for `alice`. The password grant is used here only so that a terminal can get a token. A real application uses the authorization code flow and the same scope:

<!-- astrona:playground:renew -->

```sh
NAMESPACE=sessions-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
kubectl -n "$NAMESPACE" exec deploy/tester -- curl -s \
  http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
  -d grant_type=password -d client_id=inventory-cli -d username=alice -d password=alice-password \
  -d 'scope=openid offline_access' \
  | kubectl -n "$NAMESPACE" exec -i deploy/tester -- jq -r '.refresh_token' \
  | kubectl -n "$NAMESPACE" exec -i deploy/tester -- jq -R 'split(".")[1] | gsub("-";"+") | gsub("_";"/") | . + ("=" * ((4 - length % 4) % 4)) | @base64d | fromjson | {typ}'
```

The refresh token is a JWT too. The command prints its `typ` claim, which is `Offline`. The server, not the token, decides when an offline session ends.

## What keeps an offline token alive

Two realm limits apply. `offlineSessionIdleTimeout` (default 2592000 seconds, 30 days) ends an offline session that is not used for that long. Each time the client uses the token to get a new access token, the idle clock restarts. `offlineSessionMaxLifespanEnabled` (default `false`) switches on a hard limit, `offlineSessionMaxLifespan` (default 5184000 seconds, 60 days), after which the token ends even when it is used all the time.

```sh
kcadm get realms/inventory --fields offlineSessionIdleTimeout,offlineSessionMaxLifespanEnabled,offlineSessionMaxLifespan
kcadm update realms/inventory -s offlineSessionIdleTimeout=604800
```

Setting the idle limit to 604800 seconds gives a week. Use the maximum limit too when the policy says that no access may last forever. The realm field `revokeRefreshToken` makes every refresh token usable once, and `refreshTokenMaxReuse` allows a number of reuses. Both apply to offline tokens as well.

## Finding and revoking an offline session

The Admin REST API lists the offline sessions of a user for one client. It needs the user's `id` and the client's internal `id`:

```sh
USER_ID=$(kcadm get users -r inventory -q username=alice -q exact=true --fields id --format csv --noquotes | tr -d '\r')
CLIENT_UUID=$(kcadm get clients -r inventory -q clientId=inventory-cli --fields id --format csv --noquotes | tr -d '\r')
kcadm get "users/$USER_ID/offline-sessions/$CLIENT_UUID" -r inventory
```

The result is a list with one offline session, with its start time and last access time. To revoke it, delete the session. The query parameter `isOffline=true` tells Keycloak to delete the offline session and not the online one with the same id:

```sh
SESSION_ID=$(kcadm get "users/$USER_ID/offline-sessions/$CLIENT_UUID" -r inventory --fields id --format csv --noquotes | tr -d '\r' | head -1)
kcadm delete "sessions/$SESSION_ID?isOffline=true" -r inventory
kcadm get "users/$USER_ID/offline-sessions/$CLIENT_UUID" -r inventory
```

The last command prints an empty list. The application that holds the offline refresh token gets the error `invalid_grant` the next time it tries to refresh.

Ending a user's online sessions with the `logout` endpoint does not remove the offline sessions. That is the point of the offline token, and also the reason to remember it when you offboard a user.

You can now request, limit and revoke offline access. The module's lab asks you to put the session and token limits in place and to revoke one user's offline session.

## Your mission: Set Session And Token Limits And Revoke Offline Access Lab

You can now set the session and token limits of a realm and a client and end an offline session. The mission asks you to set the limits the task lists and revoke the offline session of `bob`, and to keep the one of `alice`.

Pause the playground, start the lab and submit it when you are done:

```sh
astrona stop ats-089-playground-050-02
astrona run --git ssh://git@github.com/astrona-io/ATS089.git -c sections/section-050/module-02/labs/lab-01
astrona submit -c sections/section-050/module-02/labs/lab-01
```

When the lab is finished, remove it and start the playground again:

```sh
astrona destroy ats-089-lab-050-02
astrona start ats-089-playground-050-02
```

## Common pitfalls

> [!WARNING]
> - **Thinking `logout` ends offline access.** It ends online sessions. Delete the offline session with `isOffline=true`.
> - **Deleting without `isOffline=true`.** Keycloak looks for an online session with that id and finds nothing.
> - **Leaving the maximum limit off.** With `offlineSessionMaxLifespanEnabled` false, a token used often never ends.
> - **Handing out `offline_access` to everyone.** Every default user has the role. Remove it from the default roles when offline access is not needed.
