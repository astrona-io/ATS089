# Localization And Themes

Users read the sign-in page, the account console and the emails Keycloak sends, so the language and the look matter. A realm controls both. This part shows how to enable several languages, how Keycloak picks one for a visitor and how the four themes of a realm are chosen.

## Languages

A realm shows its pages in one language until you turn on **internationalization**. The realm field `internationalizationEnabled` switches it on. The field `supportedLocales` lists the languages the realm offers, as short codes such as `en` and `da`, and `defaultLocale` names the one used when nothing else decides.

Keycloak picks the language for a visitor in this order: the language the user saved in their profile, then the language the browser sends in its `Accept-Language` header, and then the default of the realm. A realm with internationalization on shows a language selector on the sign-in page.

Paste the helper, then enable English and Danish with English as the default:

<!-- astrona:playground:renew -->

```sh
NAMESPACE=realm-settings-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
kcadm update realms/inventory -s internationalizationEnabled=true \
  -s 'supportedLocales=["en","da"]' -s defaultLocale=en
kcadm get realms/inventory --fields internationalizationEnabled,supportedLocales,defaultLocale
```

The read prints the three fields. Now ask for the sign-in page with a Danish `Accept-Language` header and look at the `lang` attribute of the HTML. The `-H` option of `curl` sets the header:

```sh
kubectl -n "$NAMESPACE" exec deploy/tester -- curl -s -H 'Accept-Language: da' \
  'http://keycloak:8080/realms/inventory/protocol/openid-connect/auth?client_id=inventory-web&response_type=code&scope=openid&redirect_uri=http%3A%2F%2Fkeycloak%3A8080%2Fcallback' \
  | grep -o '<html[^>]*>'
```

The `<html>` tag carries `lang="da"`, because the browser asked for Danish and the realm supports it. Change the header to `fr` and the tag shows the default `en`, because `fr` is not in `supportedLocales`.

## Themes

A **theme** is a set of templates, style sheets and message files that decide how Keycloak looks. A realm has four theme fields, one for each kind of page:

- `loginTheme` styles the sign-in, registration and required action pages.
- `accountTheme` styles the account console where users manage their own data.
- `adminTheme` styles the Admin Console.
- `emailTheme` styles the emails Keycloak sends.

When a field is empty, the realm uses the default theme for that kind. The login theme `keycloak` and the base theme `base` ship with the server. You can select a theme for each kind separately:

```sh
kcadm update realms/inventory -s loginTheme=keycloak -s emailTheme=keycloak
kcadm get realms/inventory --fields loginTheme,accountTheme,adminTheme,emailTheme
```

A theme that does not exist on the server is not rejected when you save it. Keycloak falls back to a default theme when it renders a page, so a typo in a theme name shows up as a page that looks different from what you intended, not as an error. Custom themes are added as a directory or a JAR in the server's `providers` or `themes` location, which is a development topic.

The sign-in page also shows the **display name** of the realm, from the field `displayName`, and the HTML variant `displayNameHtml`. The field `realm` is the realm's name in URLs and never changes. Setting `displayName` only changes what users read:

```sh
kcadm update realms/inventory -s displayName="Inventory Portal"
```

You can now control the language and the look of the pages from the terminal. The three parts so far each changed one group of settings, so the module's lab asks you to change all three groups in one realm.

## Your mission: Configure Realm Login, Email And Languages Lab

You can now change the login options, the SMTP server and the languages of a realm. The mission asks you to set them in the realm `inventory` for a public sign-up page and prove the result by reading the realm back.

Pause the playground, start the lab and submit it when you are done:

```sh
astrona stop ats-089-playground-050-01
astrona run --git ssh://git@github.com/astrona-io/ATS089.git -c sections/section-050/module-01/labs/lab-01
astrona submit -c sections/section-050/module-01/labs/lab-01
```

When the lab is finished, remove it and start the playground again:

```sh
astrona destroy ats-089-lab-050-01
astrona start ats-089-playground-050-01
```

## Common pitfalls

> [!WARNING]
> - **Listing a language the realm cannot show.** A code that has no message files falls back to English.
> - **Forgetting `internationalizationEnabled`.** Without it, `supportedLocales` has no effect.
> - **Changing `realm` to rename the realm on the page.** Use `displayName`. The `realm` field is the name in every URL.
> - **Trusting a theme name that was not checked.** Keycloak accepts any name; look at the rendered page to confirm.
