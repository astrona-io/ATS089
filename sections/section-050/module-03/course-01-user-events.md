# User Events

Without a record, a question like "did this user ever sign in?" has no answer. User events give that answer, but they cost database space, so Keycloak leaves them off until an administrator decides what to keep. This part shows how to turn them on, how to choose which types to store and how long to keep them.

## What the settings are

Four settings of the realm's event configuration matter. `eventsEnabled` turns the storing of user events on. `enabledEventTypes` lists the event types to store; when the list is empty, Keycloak stores the default set. `eventsExpiration` is the number of seconds Keycloak keeps stored events, and `0` means for ever. `eventsListeners` lists the listeners that receive every event, and the default is `jboss-logging`.

An **event type** names what happened. `LOGIN` is a successful sign-in, `LOGIN_ERROR` a failed one, `LOGOUT` a sign-out, `REFRESH_TOKEN` and `REFRESH_TOKEN_ERROR` a token refresh and its failure, `CODE_TO_TOKEN` and `CODE_TO_TOKEN_ERROR` the exchange of an authorization code for tokens, `UPDATE_PASSWORD` a password change and `REGISTER` a self-registration. Each failure type has the same name as its success type with `_ERROR` added.

Paste the helper and read the current configuration. The endpoint is `events/config`:

<!-- astrona:playground:renew -->

```sh
NAMESPACE=events-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
kcadm get events/config -r inventory
```

The result shows `eventsEnabled` as `false`, the listener list with `jboss-logging`, and the other fields.

## Turning user events on

Enable events, store one week of history and choose the types. The list is a JSON array, so quote it:

```sh
kcadm update events/config -r inventory -s eventsEnabled=true -s eventsExpiration=604800 \
  -s 'enabledEventTypes=["LOGIN","LOGIN_ERROR","LOGOUT","REFRESH_TOKEN_ERROR","UPDATE_PASSWORD"]'
kcadm get events/config -r inventory --fields eventsEnabled,eventsExpiration,enabledEventTypes
```

The read prints the new values. From now on, Keycloak writes the five types to its database when they happen in the realm `inventory`.

## Reading events

Make one successful and one failed password request as `alice`, then list the events. The `max` query parameter limits the list:

```sh
for password in alice-password wrong-password; do
  kubectl -n "$NAMESPACE" exec deploy/tester -- curl -s -o /dev/null \
    http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=password -d client_id=inventory-cli -d username=alice -d password=$password
done
kcadm get events -r inventory -q max=5 --fields type,clientId,error
```

The list shows a `LOGIN` event and a `LOGIN_ERROR` event for the client `inventory-cli`. The `LOGIN_ERROR` event has an `error` field. Newest events come first.

The same call accepts filters. `type` selects an event type, `user` selects a user by `id`, `client` selects a client by its client ID, and `dateFrom` and `dateTo` select a day range written as `yyyy-MM-dd`:

```sh
kcadm get events -r inventory -q type=LOGIN_ERROR --fields type,error,ipAddress
```

You can now turn on user events and read them with filters. Sign-ins are only half of what happens in a realm. The other half is what administrators change, which is the next topic.

## Common pitfalls

> [!WARNING]
> - **Expecting history from before you turned events on.** Keycloak records only from that moment.
> - **Leaving `eventsExpiration` at 0 on a busy realm.** The events table grows without limit.
> - **Storing every type.** `REFRESH_TOKEN` events can fill the table quickly. Store the types you will read.
> - **Reading the wrong realm.** Every call needs `-r inventory`.
