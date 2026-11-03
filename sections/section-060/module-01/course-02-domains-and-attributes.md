# Domains And Attributes

An organization can own one or more email domains. A domain lets Keycloak decide which organization a user belongs to from the email address, and it lets the organization require that its members use an address from that domain. This part shows how to add domains, how matching works and how to store extra data in attributes.

## Domains

A domain is a name such as `acme.example`. A domain cannot belong to two organizations of the same realm. There are two kinds. An **exact** domain matches only that name, so `acme.example` matches `user@acme.example` but not `user@eu.acme.example`. A **wildcard** domain starts with `*.` and matches the base domain and all its subdomains, so `*.acme.example` matches `user@acme.example` and `user@eu.acme.example`.

When several domains match an address, the most specific one wins. A domain with more name parts is more specific, and an exact match wins over a wildcard with the same number of parts. Matching ignores case.

When an organization has no domain, Keycloak does not check the email addresses of its members against a domain. When it has one, an address outside the domain is not accepted for its members.

Paste the helper. Set one domain on the organization `acme`; each domain in the list is an object with a `name`:

<!-- astrona:playground:renew -->

```sh
NAMESPACE=orgs-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
kcadm update realms/inventory -s organizationsEnabled=true
kcadm get organizations -r inventory --fields id,alias
```

If the list is empty, create the organization first as in the previous part. Then store the id and set the domain:

```sh
ORG=$(kcadm get organizations -r inventory | kubectl -n "$NAMESPACE" exec -i deploy/tester -- jq -r '.[] | select(.alias=="acme") | .id')
kcadm update "organizations/$ORG" -r inventory -s 'domains=[{"name":"acme.example"}]'
kcadm get "organizations/$ORG" -r inventory --fields alias,domains
```

The read shows the domain list. A second organization cannot take the same domain.

## Attributes

An organization can carry attributes: named values that hold facts the realm does not model, such as a customer number or a contact. Each value is a list of strings. Set an attribute and read it back:

```sh
kcadm update "organizations/$ORG" -r inventory -s 'attributes={"customer-number":["10042"]}'
kcadm get "organizations/$ORG" -r inventory --fields alias,attributes
```

Setting `attributes` replaces the whole map, so include every attribute you want to keep. By default attributes are not in tokens. The mapper of the `organization` scope has options to add the organization id and the attributes to the claim, which the last part shows.

## Domain routing

A domain can also route users to an identity provider that is linked to the organization, and it can redirect them there without showing the sign-in form. That needs an identity provider, so this module only names it. The email domain is the key that makes the routing work.

You now know how a domain identifies an organization. Next come the people in it.

## Common pitfalls

> [!WARNING]
> - **Sharing a domain between organizations.** A domain belongs to one organization in a realm.
> - **Expecting `acme.example` to match subdomains.** Use `*.acme.example` for those.
> - **Replacing attributes by accident.** Setting `attributes` overwrites the map.
> - **Storing secrets in attributes.** If the mapper adds attributes to a token, every client sees them.
