# Summary

A user is an account in one realm, with built-in fields, attributes, credentials and a state. Keycloak finds every user by a generated `id` that never changes, which is why you fix a user instead of deleting and recreating them.

## What you learned

The user profile is the realm's list of user attributes and their rules. By default, `email`, `firstName` and `lastName` are required for the role `user` only. An administrator can create a user with nothing but a username, but that user meets the required action `VERIFY_PROFILE` at the next sign-in and cannot finish until the profile is complete. Unmanaged attributes, those not in the profile, are refused by default.

A credential is something a user proves who they are with, such as a password or an OTP device. A temporary password adds the required action `UPDATE_PASSWORD`. A required action is a task that stands between a correct password and a token. In a browser it is a form. On the password grant it is a refusal with the error `invalid_grant`, and only the `error_description` and the user's settings tell the cause: a pending action, a disabled account or an incomplete profile.

Groups collect users, and their members can be added and removed through the user's `groups` sub-resource. Offboarding keeps the record: disable the account, remove it from its groups, and end its sessions with the `logout` endpoint, because disabling alone does not end them. Impersonation lets an administrator with the `impersonation` role sign in as a user, and Keycloak records it as an event.

- A correct password is not enough: the account must be enabled, complete and free of pending required actions.
- Fix the user, not the realm's rule.
- Disabling stops new sign-ins; logging out ends existing sessions.

<!-- astrona:playground:destroy -->
