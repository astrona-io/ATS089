# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Sessions and tokens

## Scenario

The `outpost` security team found that access tokens in the realm `inventory` live five minutes, that sessions stay open for ten hours, and that `bob`, who left the team, still holds an offline token. They want shorter limits, a longer token for the nightly batch job and the end of `bob`'s offline access, without touching `alice`. Everything runs in the namespace `sessions-demo`.

## Your task

In the realm `inventory`:

1. Set the SSO session idle limit to 900 seconds and the SSO session maximum to 28800 seconds.
2. Set the access token lifespan of the realm to 120 seconds.
3. Give the client `inventory-batch` its own access token lifespan of 600 seconds.
4. Set the offline session idle limit to 604800 seconds and turn on the offline session maximum.
5. Revoke the offline session of `bob` for the client `inventory-cli`. Keep the offline session of `alice`.

## Constraints

- Do not delete or disable `bob` or `alice`.
- Do not change the lifespan of `inventory-cli` with a client attribute: it uses the realm value.
- Do not use `logout-all`: it would end the sessions of every user.

## Done when

- `ssoSessionIdleTimeout` is `900`, `ssoSessionMaxLifespan` is `28800`, `offlineSessionIdleTimeout` is `604800` and `offlineSessionMaxLifespanEnabled` is `true`.
- An access token for `inventory-cli` lives 120 seconds and one for `inventory-batch` lives 600 seconds.
- `bob` has no offline session for `inventory-cli`, and `alice` still has one.
