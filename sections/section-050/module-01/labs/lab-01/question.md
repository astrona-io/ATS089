# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Realm settings

## Scenario

The `outpost` supply team wants the realm `inventory` to run a public sign-up page. Visitors must be able to register themselves, reset a forgotten password and sign in with their email address. The page must be offered in English and Danish. Everything runs in the namespace `realm-settings-demo`.

## Your task

In the realm `inventory`:

1. Turn on user registration, the forgotten password link and remember me. Keep `loginWithEmailAllowed` on and `duplicateEmailsAllowed` off.
2. Configure the SMTP server with host `mail.example.com`, port `25`, from address `noreply@inventory.example.com` and display name `Inventory Support`, without authentication.
3. Turn on internationalization with the supported languages `en` and `da` and the default language `en`.
4. Set the display name of the realm to `Inventory Portal`.

## Constraints

- Do not change the realm `master`.
- Do not turn on `verifyEmail`: the mail server is a placeholder and no user could finish signing in.
- Do not delete or recreate the realm.

## Done when

- `registrationAllowed`, `resetPasswordAllowed` and `rememberMe` are `true`, and `duplicateEmailsAllowed` is `false`.
- `smtpServer` has the host, port, from address and display name above.
- `internationalizationEnabled` is `true`, `supportedLocales` is `en` and `da`, and `defaultLocale` is `en`.
- `displayName` is `Inventory Portal`, and the sign-in page links to registration and forgotten password.
