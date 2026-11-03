# Summary

A realm decides how its sign-in experience behaves through fields of one JSON document, the realm representation. The Admin Console and `kcadm.sh` both edit that document, and an update changes only the fields you name.

## What you learned

The login options are boolean fields. `registrationAllowed` shows the Register link, `resetPasswordAllowed` shows the Forgot Password link, `rememberMe` shows the checkbox, `loginWithEmailAllowed` lets users sign in with an email address, and `duplicateEmailsAllowed` allows one address on two users. Keycloak turns `loginWithEmailAllowed` off when duplicate emails are on. A request for the sign-in page proves what a setting does.

Email goes through the SMTP server stored in `smtpServer`, with the values `host`, `port`, `from`, `fromDisplayName`, `auth`, `user`, `password`, `ssl` and `starttls`. Features that send email, such as forgotten password and `verifyEmail`, need it. With `verifyEmail` on and no working server, a user with an unverified address cannot finish signing in, and an administrator can set `emailVerified` on the user to unblock them.

Internationalization uses `internationalizationEnabled`, `supportedLocales` and `defaultLocale`; Keycloak picks the user's saved language, then the browser's, then the default. The four themes are `loginTheme`, `accountTheme`, `adminTheme` and `emailTheme`, and a theme name that does not exist is not rejected. The realm's `displayName` changes what users read, while `realm` is the fixed name in URLs.

- Setting a nested value with a dotted name changes one value; setting the whole object replaces it.
- Read every change back, then look at the page or endpoint users reach.
- A feature that needs another service works only when that service is configured.

<!-- astrona:playground:destroy -->
