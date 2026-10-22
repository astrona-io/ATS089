# Summary

An authentication flow is the ordered tree of steps Keycloak runs when a user signs in. Changing how users sign in means changing a flow, and the safe way is always the same: copy the built-in flow, change the copy, check it, then bind it.

## What you learned

Each step of a flow is an execution with a requirement. `REQUIRED` must succeed, `ALTERNATIVE` steps at one level need one success, `CONDITIONAL` subflows run only when all their conditions are true, and `DISABLED` steps are skipped. Built-in flows cannot be changed; their copies can. A flow does nothing until a realm binding names it, and the browser and the direct grant have separate bindings, so a second factor in the browser flow does not touch the password grant.

A password policy is a string of rules, such as `length(12) and digits(1)`, that Keycloak checks whenever a password is set, not for existing passwords. The OTP policy says how one-time codes are made, and the required action `CONFIGURE_TOTP` lets a user set up a device. To ask only stock administrators for OTP, a copy of the browser flow replaces `Condition - user configured` with `Condition - user role`, configured with the role in `condUserRole`, and both the condition and the OTP form must be `REQUIRED`.

WebAuthn signs a challenge with a key pair kept on the user's device, so a fake site gets nothing it can use. A passkey is a WebAuthn credential that replaces the password. It needs the WebAuthn Passwordless Policy, with user verification `required`, and the enabled required action `webauthn-register-passwordless`. Registering a passkey needs a browser and an authenticator, so its setup is checked by reading the configuration back.

- Copy, change, check, bind.
- New executions start `DISABLED`.
- The password grant runs the `direct grant` flow, not the browser flow.

<!-- astrona:playground:destroy -->
