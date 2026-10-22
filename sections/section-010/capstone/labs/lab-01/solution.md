# Solution: Onboard And Offboard Users With kcadm.sh

Work the task yourself first. Running `astrona submit -c sections/section-010/capstone/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the two new users are onboarded correctly, `mallory` is offboarded and kept, and `alice` is unchanged.

## Step 1: Set up the helpers

`kcadm` runs Keycloak's administration command-line tool in the Keycloak pod. `user_id` and `group_id` print the `id` of a user or a top-level group:

```sh
NAMESPACE=userscapstone-demo
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

## Step 2: Create erin and frank with a complete profile

Create each user with all the profile values at once, so they never meet `VERIFY_PROFILE`:

```sh
kcadm create users -r inventory -s username=erin -s enabled=true \
  -s email=erin@example.com -s emailVerified=true -s firstName=Erin -s lastName=Lind
kcadm create users -r inventory -s username=frank -s enabled=true \
  -s email=frank@example.com -s emailVerified=true -s firstName=Frank -s lastName=Moss
```

## Step 3: Give them a temporary password

`--temporary` sets the password and adds the required action `UPDATE_PASSWORD`, so each user must choose a new password at the first sign-in:

```sh
for user in erin frank; do
  kcadm set-password -r inventory --username "$user" --new-password Welcome-2026-Start --temporary
done
```

## Step 4: Add them to warehouse

Membership is the path `users/<user id>/groups/<group id>`. The `-n` option skips reading the path first:

```sh
for user in erin frank; do
  kcadm update "users/$(user_id "$user")/groups/$(group_id warehouse)" -r inventory \
    -s realm=inventory -s userId="$(user_id "$user")" -s groupId="$(group_id warehouse)" -n
done
```

Check one of them. The record shows `UPDATE_PASSWORD` in `requiredActions`, and the groups list shows `warehouse`:

```sh
kcadm get "users/$(user_id erin)" -r inventory --fields username,email,firstName,lastName,requiredActions
kcadm get "users/$(user_id erin)/groups" -r inventory --fields name
```

## Step 5: Offboard mallory

First look at her sessions. The list shows the sessions the lab opened for her:

```sh
kcadm get "users/$(user_id mallory)/sessions" -r inventory
```

Disable the account, remove it from the group, and end every session. Disabling alone stops new sign-ins but leaves existing sessions in place:

```sh
kcadm update "users/$(user_id mallory)" -r inventory -s enabled=false
kcadm delete "users/$(user_id mallory)/groups/$(group_id warehouse)" -r inventory
kcadm create "users/$(user_id mallory)/logout" -r inventory
kcadm get "users/$(user_id mallory)/sessions" -r inventory
```

The last command prints an empty list.

## Step 6: Prove it from the token endpoint

`mallory` must get no token, and `alice` must still get one:

```sh
for user in mallory alice; do
  printf '%s: ' "$user"
  kubectl -n "$NAMESPACE" exec deploy/tester -- curl -s \
    http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=password -d client_id=inventory-cli -d username="$user" -d password="$user-password" \
    | jq -r 'if .access_token then "token" else .error_description end'
done
```

The line for `mallory` shows a description that says the account is disabled, and the line for `alice` says `token`.

## Step 7: Submit

```sh
astrona submit -c sections/section-010/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Delete `mallory` | the audit trail loses its link to her, and the grader rejects it |
| Disable `mallory` without logging her out | her existing sessions stay until they expire |
| Give `erin` and `frank` a permanent password | they never choose their own, so the administrator knows their password |
| Create the users with only a username | they must fill in their profile at the first sign-in, and the grader checks the names and email |
