# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Events and admin events

## Scenario

The `outpost` support team cannot tell why `alice` was refused at the start of the day, and the security team cannot tell who changes groups in the realm `inventory`. The realm records nothing, because events are off. Everything runs in the namespace `events-demo`.

## Your task

In the realm `inventory`:

1. Turn on user events. Store the types `LOGIN`, `LOGIN_ERROR` and `LOGOUT`, and keep events for 604800 seconds.
2. Turn on admin events and the representation of the changed object.
3. Make one failed password request for `alice` with the client `inventory-cli`, so that a `LOGIN_ERROR` event is recorded.
4. Create a group named `ops-audit`, so that an admin event is recorded.

## Constraints

- Do not enable any event type outside the three named.
- Do not delete the user `alice`.
- Do not clear the events after you create them.

## Done when

- `eventsEnabled` is `true`, `eventsExpiration` is `604800` and `enabledEventTypes` holds `LOGIN`, `LOGIN_ERROR` and `LOGOUT`.
- `adminEventsEnabled` and `adminEventsDetailsEnabled` are both `true`.
- A `LOGIN_ERROR` event for `alice` with the error `invalid_user_credentials` exists.
- An admin event that created the group `ops-audit` exists, with its representation.
