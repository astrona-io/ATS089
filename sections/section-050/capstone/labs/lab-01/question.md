# Question

Solve this question on: `terminal`

**Time:** about 35 minutes · **Topic:** Realm settings, sessions and events

## Scenario

Since a settings change last week, users of the realm `inventory` at `outpost` are signed out within two minutes, their tokens expire after ten seconds, nobody can reset a forgotten password, and `bob` says he cannot sign in at all. Nobody knows why `bob` is refused, because the realm records no events. Everything runs in the namespace `realm-audit-capstone`.

## Your task

Repair the realm `inventory` without recreating it:

1. Find the cause of the refusal of `bob`. Turn on user events for the types `LOGIN` and `LOGIN_ERROR`, make a password request for `bob` with the client `inventory-cli`, read the `error` of the event, and fix the cause so that `bob` gets a token.
2. Show the Forgot Password link and the remember me checkbox on the sign-in page.
3. Set the SSO session idle limit to 1800 seconds and the access token lifespan to 300 seconds.

## Constraints

- Do not delete or recreate the realm, the users or the client.
- Do not change the password of `bob` or `alice`: the cause is not the password.
- Do not clear the events: the grader reads the failed sign-in.
- Keep `alice` able to get a token.

## Done when

- A `LOGIN_ERROR` event for `bob` with the error `user_disabled` exists, and `eventsEnabled` is `true` with `LOGIN_ERROR` in `enabledEventTypes`.
- `bob` and `alice` both get an access token.
- `resetPasswordAllowed` and `rememberMe` are `true`.
- `ssoSessionIdleTimeout` is `1800` and `accessTokenLifespan` is `300`.
