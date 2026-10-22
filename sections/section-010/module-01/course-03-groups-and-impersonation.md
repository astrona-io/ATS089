# Groups, Disabling Users And Impersonation

Users come and go in teams. When a team grows, you want to give every new member the same access in one step. When someone leaves, you want their access gone at once, but the record kept for audits. This part covers groups, the safe way to offboard a user, and impersonation, the administrator's way to see what one user sees.

## Groups

A **group** is a set of users in a realm. Roles and attributes set on a group apply to every member, and a group can have subgroups that inherit from it. Groups are how you manage access for many users at once.

Paste the helpers for this part. `kcadm` runs Keycloak's administration command-line tool in the Keycloak pod. `user_id` and `group_id` print the `id` of a user or a top-level group:

<!-- astrona:playground:renew -->

```sh
NAMESPACE=users-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
user_id() {
  kcadm get users -r inventory -q username="$1" -q exact=true --fields id --format csv --noquotes | tr -d '\r'
}
group_id() {
  kcadm get groups -r inventory -q search="$1" --fields id,name --format csv --noquotes \
    | tr -d '\r' | awk -F, -v name="$1" '$2 == name {print $1; exit}'
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
```

List the members of the group `warehouse`, then add `bob`. Membership is a sub-resource of the user: `users/<user id>/groups/<group id>`. The `-n` option tells `kcadm.sh` not to read the object first, because there is nothing to read:

```sh
kcadm get "groups/$(group_id warehouse)/members" -r inventory --fields username
kcadm update "users/$(user_id bob)/groups/$(group_id warehouse)" -r inventory \
  -s realm=inventory -s userId="$(user_id bob)" -s groupId="$(group_id warehouse)" -n
kcadm get "users/$(user_id bob)/groups" -r inventory --fields name
```

The first command lists only `alice`. The last command lists `warehouse` for `bob`. To remove a member, delete the same path: `kcadm delete users/<user id>/groups/<group id>`.

## Offboarding without deleting

When a person leaves, deleting their account looks tidy, but it destroys the record that audits and investigations need. The safe offboarding has three steps: disable the account, remove it from its groups, and end its sessions.

A **session** is Keycloak's record that a user signed in. Every token request with the password grant creates one. Make two sessions for `bob`, then look at them:

```sh
for attempt in 1 2; do
  kubectl -n "$NAMESPACE" exec deploy/tester -- curl -s -o /dev/null \
    http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=password -d client_id=inventory-cli -d username=bob -d password=bob-password
done
kcadm get "users/$(user_id bob)/sessions" -r inventory
```

The output lists two sessions, each with its start time and the client `inventory-cli`. Disabling `bob` stops new sign-ins. It does not by itself end the sessions he already has, so end them with the `logout` endpoint, and check:

```sh
kcadm update "users/$(user_id bob)" -r inventory -s enabled=false
kcadm create "users/$(user_id bob)/logout" -r inventory
kcadm get "users/$(user_id bob)/sessions" -r inventory
```

The last command prints an empty list. An access token that `bob` already holds stays valid until it expires, which is five minutes by default, so short token lifetimes matter for offboarding.

Turn `bob` back on before you continue, so the rest of the playground keeps working:

```sh
kcadm update "users/$(user_id bob)" -r inventory -s enabled=true
```

## Impersonation

**Impersonation** lets an administrator sign in as another user, to see exactly what that user sees. It needs the role `impersonation` of the client `realm-management`; the `admin` user of `master` has it. In the Admin Console you open the user and choose **Impersonate** from the **Action** menu. Keycloak then opens the account console of the realm, signed in as that user.

The same action is a call to the Admin REST API. Run it for `alice`:

```sh
kcadm create "users/$(user_id alice)/impersonation" -r inventory
```

The response is JSON with a `redirect` URL to the account console of `inventory`. Keycloak also created a session for `alice` and recorded an `IMPERSONATE` event. Impersonation is powerful: the administrator acts as the user, so grant the `impersonation` role only to people who need it.

You now know how to manage users in groups, end a user's access without losing the record, and see the realm through one user's eyes. These skills come together when people join and leave a team, which is the subject of this section's capstone.

## Common pitfalls

> [!WARNING]
> - **Deleting a leaver's account.** The record, the group history and the audit link are gone. Disable the account instead.
> - **Disabling without logging out.** Existing sessions stay until they end. Call `users/<id>/logout` as well.
> - **Forgetting `-n` on a membership update.** Without it, `kcadm.sh` tries to read the path first and fails, because a membership has nothing to read.
> - **Searching groups by a partial name.** `-q search=ware` matches more than one group. Filter the result by the exact name.
