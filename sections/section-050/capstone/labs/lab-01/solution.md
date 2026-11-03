# Solution: Fix A Realm That Locks Users Out

Work the task yourself first. Running `astrona submit -c sections/section-050/capstone/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks four things: the event and the event configuration, tokens for both users, the two login options and the two limits.

## Step 1: Set up the helper

```sh
NAMESPACE=realm-audit-capstone
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
kcadm get realms/inventory --fields resetPasswordAllowed,rememberMe,ssoSessionIdleTimeout,accessTokenLifespan
kcadm get events/config -r inventory --fields eventsEnabled,enabledEventTypes
```

The read shows two login options off, a 120 second idle limit, a 10 second token lifespan and events off.

## Step 2: Record the failure and read its cause

Turn on events first, because only events that happen afterwards are recorded:

```sh
kcadm update events/config -r inventory -s eventsEnabled=true -s eventsExpiration=604800 \
  -s 'enabledEventTypes=["LOGIN","LOGIN_ERROR"]'
kubectl -n "$NAMESPACE" exec deploy/tester -- curl -s \
  http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
  -d grant_type=password -d client_id=inventory-cli -d username=bob -d password=bob-password
kcadm get events -r inventory -q type=LOGIN_ERROR -q max=5 --fields error,details
```

The token endpoint answers with a vague `invalid_grant`. The event names the cause: `user_disabled`.

## Step 3: Enable bob and fix the realm settings

```sh
BOB=$(kcadm get users -r inventory -q username=bob -q exact=true --fields id --format csv --noquotes | tr -d '\r')
kcadm update "users/$BOB" -r inventory -s enabled=true
kcadm update realms/inventory -s resetPasswordAllowed=true -s rememberMe=true \
  -s ssoSessionIdleTimeout=1800 -s accessTokenLifespan=300
```

## Step 4: Check the result and submit

```sh
kcadm get realms/inventory --fields resetPasswordAllowed,rememberMe,ssoSessionIdleTimeout,accessTokenLifespan
astrona submit -c sections/section-050/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Reset the password of bob | The password was never the cause, and the task forbids it |
| Enable bob before turning on events | No event is recorded, so the grader finds no failed sign-in |
| Clear the events after reading them | Removes the evidence the grader checks |
| Recreate the realm | Breaks the constraint and loses the users |
