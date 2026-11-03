# Testing And Troubleshooting LDAP

The provider is saved and no LDAP user can sign in. The cause is in one of four places: the connection, the bind credential, the users DN or the attribute mapping. This part tests each one separately, so you know which of the four to fix.

## Test the connection and the bind

Keycloak has two test calls. Both post a small body to the realm and return no content when they work and an error when they do not. Paste the helper:

<!-- astrona:playground:renew -->

```sh
NAMESPACE=ldap-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
kcadm create testLDAPConnection -r inventory -s action=testConnection \
  -s connectionUrl=ldap://openldap:389 -s authType=simple
echo "exit code: $?"
kcadm create testLDAPConnection -r inventory -s action=testAuthentication \
  -s connectionUrl=ldap://openldap:389 -s authType=simple \
  -s bindDn=cn=admin,dc=example,dc=org -s bindCredential=ldap-admin-password
echo "exit code: $?"
```

The first call tests only the network path to the server: the name resolves and the port answers. The second signs in with the bind DN and the credential. A wrong host fails the first call. A wrong password or DN fails the second, and the first still passes. This split tells you whether to look at the network or at the credential.

## Test the users DN with a search

The bind can work while the users DN is wrong. The directory then has no users under it. Search the directory from the pod that has the LDAP tools, or sign a known user in. The `tester` pod sends a token request for `ldap-ana`:

```sh
kubectl -n "$NAMESPACE" exec deploy/tester -- curl -s \
  http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
  -d grant_type=password -d client_id=inventory-cli -d username=ldap-ana -d password=ana-password \
  | kubectl -n "$NAMESPACE" exec -i deploy/tester -- jq '{error, error_description}'
```

An `invalid_grant` for a user who exists means the user was not found under the users DN, or the password is wrong. Read the provider's users DN and compare it with the directory:

```sh
kcadm get components -r inventory -q name=openldap --fields name,config.usersDn,config.usernameLDAPAttribute,config.userObjectClasses
```

## Read the log

The Keycloak log names the failing step. Search for the provider and for LDAP errors:

```sh
kubectl -n "$NAMESPACE" logs deploy/keycloak --tail=200 | grep -i ldap
```

An error with `Invalid Credentials` points to the bind. A `Connection refused` or `UnknownHostException` points to the URL. A user that is found but has an empty name points to the username attribute.

## A decision order

Test in this order and stop at the first failure. First the connection, because nothing works without it. Second the bind, because a search needs it. Third the users DN with a known user. Fourth the mappers, by reading one imported user. Fixing a later step while an earlier one fails changes nothing.

## Common pitfalls

> [!WARNING]
> - **Testing only the connection.** It passes with a wrong password. Test the authentication too.
> - **Changing the mappers first.** If the users DN is wrong, no mapper is reached.
> - **Using `localhost` in the URL.** From the Keycloak pod it is the pod itself. Use the Service name `openldap`.
> - **Reading the password into the shell history.** Use lab-only credentials, as here.
