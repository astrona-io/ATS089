# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Authentication

## Scenario

A security review of the realm `inventory` asks for two changes:

- Every new password must be at least 12 characters long and contain at least one digit.
- Users with the realm role `stock-admin` must enter a one-time password (OTP) when they sign in through a browser. Nobody else is asked for one, even a user who has set up an OTP device.

Today the realm has no password policy and uses the built-in `browser` flow. `bob` holds `stock-admin`; `alice` does not.

## Your task

In the realm `inventory` and the namespace `flows-demo`:

1. Set the password policy to require a length of 12 and one digit.
2. Create a copy of the `browser` flow named `browser-stock-admin-otp`. In its conditional second-factor subflow, ask for OTP only when the user has the realm role `stock-admin`: the role condition and the OTP form must be `REQUIRED`, and the condition on a configured OTP device must not be active.
3. Bind `browser-stock-admin-otp` as the realm's browser flow.

## Constraints

- **Do not change the built-in flows**, and do not change the direct grant binding. Users of the password grant, such as `inventory-cli`, must keep signing in as before.
- Do not change the passwords of `alice` (`alice-password`) and `bob` (`bob-password`). The policy applies to new passwords only, so their current passwords keep working.
- Registering an OTP device needs a browser and an app. The grader checks the flow's configuration, not a real OTP sign-in.

## Done when

- The password policy refuses `short1` and accepts a 12-character password with a digit.
- `browser-stock-admin-otp` is bound as the browser flow, has `Condition - user role` set to `stock-admin` and `REQUIRED`, an active OTP form, and no active `Condition - user configured`.
- The direct grant binding is still `direct grant`, and `alice` and `bob` still get tokens with the password grant.
