# Solution: Configure Realm Login, Email And Languages

Work the task yourself first. Running `astrona submit -c sections/section-050/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the login options, the SMTP server and the languages, plus the page links.

## Step 1: Set up the helper

```sh
NAMESPACE=realm-settings-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
```

## Step 2: Set the login options and the display name

```sh
kcadm update realms/inventory -s registrationAllowed=true -s resetPasswordAllowed=true -s rememberMe=true \
  -s loginWithEmailAllowed=true -s duplicateEmailsAllowed=false -s displayName="Inventory Portal"
```

## Step 3: Configure the SMTP server

Use the dotted names so that each value is set on its own:

```sh
kcadm update realms/inventory \
  -s smtpServer.host=mail.example.com -s smtpServer.port=25 \
  -s smtpServer.from=noreply@inventory.example.com \
  -s smtpServer.fromDisplayName="Inventory Support" -s smtpServer.auth=false
```

## Step 4: Turn on the languages

```sh
kcadm update realms/inventory -s internationalizationEnabled=true \
  -s 'supportedLocales=["en","da"]' -s defaultLocale=en
```

## Step 5: Read the result back and look at the page

```sh
kcadm get realms/inventory --fields registrationAllowed,resetPasswordAllowed,rememberMe,smtpServer,supportedLocales,defaultLocale,displayName
kubectl -n "$NAMESPACE" exec deploy/tester -- curl -s \
  'http://keycloak:8080/realms/inventory/protocol/openid-connect/auth?client_id=inventory-web&response_type=code&scope=openid&redirect_uri=http%3A%2F%2Fkeycloak%3A8080%2Fcallback' \
  | grep -o -e 'login-actions/registration' -e 'login-actions/reset-credentials' | sort -u
```

## Step 6: Submit

```sh
astrona submit -c sections/section-050/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Turn on `verifyEmail` to "finish" email setup | the placeholder server cannot send mail, so users with an unverified address cannot sign in |
| Set `smtpServer` as one JSON value | it replaces every value inside it, including values you set earlier |
| Set `supportedLocales` without `internationalizationEnabled` | the realm shows no language selector |
| Delete and recreate the realm | every user and client is lost |
