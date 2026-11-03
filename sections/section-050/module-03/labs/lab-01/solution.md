# Solution: Turn On Events And Find A Failed Sign-In

Work the task yourself first. Running `astrona submit -c sections/section-050/module-03/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the event configuration, the failed sign-in event and the admin event for the group.

## Step 1: Set up the helper

```sh
NAMESPACE=events-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
```

## Step 2: Turn on both kinds of events

```sh
kcadm update events/config -r inventory -s eventsEnabled=true -s eventsExpiration=604800 \
  -s 'enabledEventTypes=["LOGIN","LOGIN_ERROR","LOGOUT"]' \
  -s adminEventsEnabled=true -s adminEventsDetailsEnabled=true
kcadm get events/config -r inventory --fields eventsEnabled,eventsExpiration,enabledEventTypes,adminEventsEnabled,adminEventsDetailsEnabled
```

## Step 3: Produce the two events

Events are recorded only after the setting is on, so do this after step 2:

```sh
kubectl -n "$NAMESPACE" exec deploy/tester -- curl -s -o /dev/null \
  http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
  -d grant_type=password -d client_id=inventory-cli -d username=alice -d password=wrong-password
kcadm create groups -r inventory -s name=ops-audit
```

## Step 4: Read the evidence

```sh
kcadm get events -r inventory -q type=LOGIN_ERROR -q max=5 --fields type,error,details
kcadm get admin-events -r inventory -q resourceTypes=GROUP -q max=5 --fields operationType,resourcePath,representation
```

The first event has the error `invalid_user_credentials`. The second has the operation `CREATE` and a representation that holds `ops-audit`.

## Step 5: Submit

```sh
astrona submit -c sections/section-050/module-03/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Make the failed request before turning events on | Nothing is recorded, so the check finds no event |
| Turn on admin events without details | The event exists but has no representation, so the check cannot see the group name |
| `kcadm delete events` to tidy up | Removes the evidence |
| Store all event types | Breaks the constraint and fills the table |
