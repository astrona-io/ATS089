# Reading And Changing The Realm Representation

Every setting in this module is one field of the same JSON document. Knowing how that document behaves saves you from two common mistakes: changing more than you meant, and trusting a change you never read back. This part shows how to read the whole representation, how an update merges, and how realm attributes extend it.

## One document, many settings

The **realm representation** is the JSON that `GET /admin/realms/<name>` returns. It holds the login options, the SMTP server, the languages, the themes, the token and session lifespans, the password policy and much more. The Admin Console edits this same document.

Paste the helper. Count the top-level fields, then list the first ones with `jq` in the `tester` pod, because your machine may not have `jq`:

<!-- astrona:playground:renew -->

```sh
NAMESPACE=realm-settings-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
kcadm get realms/inventory | kubectl -n "$NAMESPACE" exec -i deploy/tester -- jq 'keys | length'
kcadm get realms/inventory | kubectl -n "$NAMESPACE" exec -i deploy/tester -- jq -r 'keys[:10][]'
```

The first command prints the number of top-level fields. The second prints the names of the first ten. Use `--fields name1,name2` when you need only a few, as the earlier parts did.

## An update merges what you send

`kcadm update realms/<name> -s field=value` first reads the current document, changes the field you named and sends the whole document back. Fields you did not name keep their values. That is why the earlier commands changed one setting without resetting the rest.

Prove it. Read two unrelated fields, change one, and read both again:

```sh
kcadm get realms/inventory --fields rememberMe,displayName
kcadm update realms/inventory -s rememberMe=true
kcadm get realms/inventory --fields rememberMe,displayName
```

The second read shows `rememberMe` as `true` and `displayName` unchanged. A nested value such as `smtpServer` behaves the same way when you use the dotted form `smtpServer.port`. Setting `smtpServer` as a whole JSON value replaces it.

## Realm attributes

The realm representation has a field `attributes`, a map of names to string values. Keycloak stores several realm settings there, such as token behavior flags and, in later modules, the session and level-of-authentication settings. You can read and write an attribute with the dotted name `attributes.<name>`:

```sh
kcadm update realms/inventory -s attributes.siteOwner=inventory-team
kcadm get realms/inventory --fields attributes
```

The read lists `siteOwner` among the attributes. Attributes you invent have no effect on Keycloak, but they are kept, and a custom theme or provider can read them.

## Checking a change from outside

A change is real when a request from outside the Admin API sees it. The `.well-known` document of the realm is public and shows part of the realm's state, for example its issuer. Request it from the `tester` pod and read the issuer, which contains the realm name:

```sh
kubectl -n "$NAMESPACE" exec deploy/tester -- sh -c \
  'curl -s http://keycloak:8080/realms/inventory/.well-known/openid-configuration | jq -r .issuer'
```

The command prints `http://keycloak:8080/realms/inventory`. Use this habit for every setting that changes what users see: read the field with `kcadm`, then look at the page or endpoint users reach.

You now know that all realm settings live in one document, that an update merges field by field, and how to prove a change from outside. The next module applies the same habit to how long users stay signed in.

## Common pitfalls

> [!WARNING]
> - **Sending a whole nested value.** `-s smtpServer={...}` replaces every value inside it. Use the dotted name for one value.
> - **Forgetting `-r`.** A command without `-r inventory` changes the `master` realm.
> - **Assuming an invented attribute does something.** Only the attribute names Keycloak knows have an effect.
> - **Not reading the value back.** A command that returns no error does not prove the new value. Read it.
