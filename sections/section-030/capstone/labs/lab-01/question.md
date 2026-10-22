# Question

Solve this question on: `terminal`

**Time:** about 35 minutes · **Topic:** Authentication

## Scenario

In the realm `inventory`, stock administrators (users with the realm role `stock-admin`) are supposed to need a second factor at a browser sign-in, and every user should be able to register a passkey. Someone made "temporary" changes during an incident, and since then:

- `bob`, a stock administrator, signs in through the browser with only his password.
- Nobody is offered the setup of an OTP app or the registration of a passkey.
- The passkey policy accepts devices that do not verify the user.

The realm's browser flow is `browser-stock-admin-otp`, and it is still bound.

## Your task

In the realm `inventory` and the namespace `flowscapstone-demo`:

1. Find every fault in the flow `browser-stock-admin-otp`, the realm's required actions, and the WebAuthn passwordless policy.
2. Repair them so that the flow asks `stock-admin` users for OTP again, users can set up OTP and register a passkey, and a passkey must verify the user.

## Constraints

- **Repair the flow that exists.** Do not delete or recreate `browser-stock-admin-otp`, and keep it bound as the browser flow. The grader compares its ID with the one the lab started with.
- Do not change the direct grant binding. `alice` (`alice-password`) and `bob` (`bob-password`) must keep getting tokens with the password grant.
- Registering an OTP device or a passkey needs a browser and an authenticator. The grader checks the configuration.
- Do not change the ConfigMap `capstone-baseline`.

## Done when

- `browser-stock-admin-otp` is the original flow, bound as the browser flow, with its conditional subflow active, `Condition - user role` set to `stock-admin`, and the OTP form active.
- The required actions `CONFIGURE_TOTP` and `webauthn-register-passwordless` are enabled.
- The passwordless WebAuthn policy requires user verification.
- `alice` and `bob` still get tokens with the password grant.
