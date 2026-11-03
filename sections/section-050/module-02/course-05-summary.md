# Summary

A session is Keycloak's record that a user signed in, and a token is the signed proof it hands to an application. Different settings limit each one, and ending one does not automatically end the other.

## What you learned

An SSO session ends at its idle limit, `ssoSessionIdleTimeout`, or at its maximum, `ssoSessionMaxLifespan`. Both are in seconds, the idle limit must not exceed the maximum, and the remember me variants replace them for users who tick the box. Client session limits are optional and cannot exceed the SSO limits.

The access token lifespan, `accessTokenLifespan`, defaults to 300 seconds. A client can override it with the attribute `access.token.lifespan`. The code lifespans are different settings for the authorization code, user actions and the sign-in page. A token states its own lifetime in `exp` and `iat`, so the difference proves the lifespan. Tokens that were already issued keep their expiry.

An offline token is a refresh token of the type `Offline`, requested with the scope `offline_access`. It lives in an offline session until the offline idle limit or the optional maximum ends it. Ending online sessions does not end it. An administrator revokes it by deleting the offline session with `isOffline=true`.

Sessions can be listed per user, per client and as counts per client. A session can be deleted by its id, a user can be logged out, and the realm can be logged out. These calls stop refresh tokens immediately, but an access token works until `exp`.

- Time values are in seconds.
- A refresh token stops working when its session ends, and a session ends at its limits.
- Short access tokens, or introspection, make offboarding take effect quickly.

<!-- astrona:playground:destroy -->
