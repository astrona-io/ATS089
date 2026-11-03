# Members

An organization is only useful when users belong to it. This part explains the two kinds of members, how to add and remove them with `kcadm.sh`, and the one difference that matters when you delete.

## Managed and unmanaged members

A **managed** member is an account that the organization controls. It cannot exist outside the organization, and when the member or the organization is removed, the account is removed from the realm too. Managed accounts come from an identity provider that is linked to the organization as managed.

An **unmanaged** member is an account that belongs to the realm first and is linked to the organization afterwards. Removing the organization or the member leaves the account in the realm. Every user you add by hand from the existing realm users is unmanaged. Use unmanaged members for users that exist independently, such as staff who work for more than one customer.

An administrator can change the type of a member with the Admin API call `PUT organizations/<id>/members/<user>/membership-type`.

## Adding and listing members

The call that adds a member takes the user id as a bare JSON string in the body. Paste the helper, create the organization if needed and add `alice`:

<!-- astrona:playground:renew -->

```sh
NAMESPACE=orgs-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
kcadm update realms/inventory -s organizationsEnabled=true
kcadm create organizations -r inventory -s name="Acme Corporation" -s alias=acme -s enabled=true
ORG=$(kcadm get organizations -r inventory | kubectl -n "$NAMESPACE" exec -i deploy/tester -- jq -r '.[] | select(.alias=="acme") | .id')
ALICE=$(kcadm get users -r inventory -q username=alice -q exact=true --fields id --format csv --noquotes | tr -d '\r')
kcadm create "organizations/$ORG/members" -r inventory -b "\"$ALICE\""
kcadm get "organizations/$ORG/members" -r inventory --fields username,membershipType
```

The list shows `alice` with the membership type `UNMANAGED`. To see which organizations a user belongs to, read the other direction:

```sh
kcadm get "organizations/members/$ALICE/organizations" -r inventory --fields alias
```

## Removing a member

```sh
kcadm delete "organizations/$ORG/members/$ALICE" -r inventory
kcadm get "organizations/$ORG/members" -r inventory
```

The list is empty, and `alice` still exists as a user of the realm because she was unmanaged:

```sh
kcadm get users -r inventory -q username=alice -q exact=true --fields username
```

## Other ways in

Besides adding an existing user, an administrator can invite a person by email. If the address matches an existing user, that user only confirms; otherwise the invitee registers with the same address. Users who sign in through an identity provider that is linked to the organization can also be added automatically when automatic membership is on and the domain matches. Both ways need email or an identity provider, which this module does not set up.

## Your mission: Create Organizations And Add Members Lab

You can now enable organizations, create them and manage members. The mission asks you to build two organizations in the realm `inventory` and place the users in them.

Pause the playground, start the lab and submit it when you are done:

```sh
astrona stop ats-089-playground-060-01
astrona run --git ssh://git@github.com/astrona-io/ATS089.git -c sections/section-060/module-01/labs/lab-01
astrona submit -c sections/section-060/module-01/labs/lab-01
```

When the lab is finished, remove it and start the playground again:

```sh
astrona destroy ats-089-lab-060-01
astrona start ats-089-playground-060-01
```

## Common pitfalls

> [!WARNING]
> - **Sending the user id as an object.** The body is the id as a JSON string, in quotes.
> - **Expecting a delete to remove the account.** Only a managed member is removed with the organization.
> - **Using the username in the path.** Member paths use the user id.
> - **Forgetting that the member is added to one organization.** A user can belong to several, and the claim then needs a wider scope.
