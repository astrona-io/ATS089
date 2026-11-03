# Finding A Failed Sign-In

A token endpoint answers a failed request with the same short `invalid_grant` for many causes. The user event for that request is more exact: its `error` field names the real cause. This part shows how to match a failed request with its event and how to read the most common errors.

## The error field

A `_ERROR` event carries an `error` value that explains the failure. For a failed password sign-in the common values are `invalid_user_credentials` (the password is wrong), `user_not_found` (no such user), `user_disabled` (the user is disabled) and `invalid_client_credentials` (the client authentication failed). The values are the ones Keycloak writes, so searching for them in events and logs is reliable.

Paste the helper. Turn on `LOGIN_ERROR` events if they are not on yet:

<!-- astrona:playground:renew -->

```sh
NAMESPACE=events-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
kcadm update events/config -r inventory -s eventsEnabled=true \
  -s 'enabledEventTypes=["LOGIN","LOGIN_ERROR","LOGOUT"]'
```

## Three failures, three events

Make three failed requests with three different causes: a wrong password, an unknown user and a disabled user. Create and disable a user for the third one:

```sh
kcadm create users -r inventory -s username=grounded -s enabled=true
kcadm set-password -r inventory --username grounded --new-password grounded-password
GROUNDED=$(kcadm get users -r inventory -q username=grounded -q exact=true --fields id --format csv --noquotes | tr -d '\r')
kcadm update "users/$GROUNDED" -r inventory -s enabled=false
try_login() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- curl -s \
    http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=password -d client_id=inventory-cli -d username="$1" -d password="$2" \
    | kubectl -n "$NAMESPACE" exec -i deploy/tester -- jq -c '{error, error_description}'
}
try_login alice wrong-password
try_login nobody nobody-password
try_login grounded grounded-password
```

The token endpoint shows `invalid_grant` for the first and last request, and a similar answer for the second. The responses are deliberately vague so that an attacker learns little. Now read the events:

```sh
kcadm get events -r inventory -q type=LOGIN_ERROR -q max=5 --fields error,details
```

Each event names its cause in `error`. The `details` field adds context such as the username that was tried. In this way an administrator sees the real cause that the response hides from the caller.

## Matching an event to a request

To find the event for one request, filter by user and client and read the `time`. The `time` is milliseconds since 1970-01-01. The tester pod can convert it:

```sh
kcadm get events -r inventory -q type=LOGIN_ERROR -q client=inventory-cli -q max=1 --fields time,error \
  | kubectl -n "$NAMESPACE" exec -i deploy/tester -- jq -r '.[0].time / 1000 | todate'
```

The command prints the time of the newest failure in UTC. If it is not the failure you expect, the request went to another client, another realm or another Keycloak.

For a support case, the sequence is short. Ask the user for the time and the username, filter events with `type=LOGIN_ERROR` and `dateFrom`, and read the `error`. Then fix the cause, not the symptom: reset the password, enable the user or correct the client.

## Your mission: Turn On Events And Find A Failed Sign-In Lab

You can now record events and read the cause of a failed sign-in. The mission asks you to turn on user and admin events in the realm `inventory`, produce one failed sign-in and one administrator change, and prove both are recorded.

Pause the playground, start the lab and submit it when you are done:

```sh
astrona stop ats-089-playground-050-03
astrona run --git ssh://git@github.com/astrona-io/ATS089.git -c sections/section-050/module-03/labs/lab-01
astrona submit -c sections/section-050/module-03/labs/lab-01
```

When the lab is finished, remove it and start the playground again:

```sh
astrona destroy ats-089-lab-050-03
astrona start ats-089-playground-050-03
```

## Common pitfalls

> [!WARNING]
> - **Reading the HTTP response as the cause.** `invalid_grant` hides the cause on purpose. Read the event.
> - **Searching without a date.** On a busy realm, add `dateFrom` and `max`.
> - **Not enabling the `_ERROR` types.** If `enabledEventTypes` has `LOGIN` but not `LOGIN_ERROR`, failures leave no trace.
> - **Reading time as seconds.** The value is in milliseconds.
