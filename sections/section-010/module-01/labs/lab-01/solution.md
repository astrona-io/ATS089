# Solution: Get Three Users Signed In Again

Work the task yourself first. Running `astrona submit -c sections/section-010/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: each of the three users gets an access token, the users are the original ones, and the user profile and `VERIFY_PROFILE` are unchanged.

## Step 1: Set up the helpers and reproduce the failures

Paste the helpers. `kcadm` runs Keycloak's administration command-line tool in the Keycloak pod. `user_id` prints a user's `id`. `get_user_token` sends the password grant from the `tester` pod:

```sh
NAMESPACE=users-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
user_id() {
  kcadm get users -r inventory -q username="$1" -q exact=true --fields id --format csv --noquotes | tr -d '\r'
}
get_user_token() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- curl -s \
    http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=password -d client_id=inventory-cli -d username="$1" -d password="$2"
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
```

Request a token for each user and read only the error:

```sh
for user in bob carol dave; do
  get_user_token "$user" "$user-password" | jq -c '{error, error_description}'
done
```

All three answers have `error` set to `invalid_grant`. For `bob` and `dave`, the description says the account is not fully set up. For `carol`, it says the account is disabled. The `error` field is the same, so the descriptions and the users' settings must tell the causes apart.

## Step 2: Read the three users

Read the fields that decide whether a user can finish signing in:

```sh
for user in bob carol dave; do
  kcadm get "users/$(user_id "$user")" -r inventory \
    --fields username,enabled,firstName,lastName,email,requiredActions
done
```

The three records show three different faults:

- `bob` is enabled and complete, but `requiredActions` holds `UPDATE_PASSWORD`. His password is temporary.
- `carol` has `enabled` set to `false`.
- `dave` is enabled and has no pending action, but his record has no `lastName`. The user profile requires a last name for the role `user`, so Keycloak runs `VERIFY_PROFILE` at his sign-in, which the password grant cannot show.

## Step 3: Fix bob

Make his password permanent and clear the pending action. The password stays `bob-password`:

```sh
kcadm set-password -r inventory --username bob --new-password bob-password
kcadm update "users/$(user_id bob)" -r inventory -s 'requiredActions=[]'
```

## Step 4: Fix carol

Enable the account:

```sh
kcadm update "users/$(user_id carol)" -r inventory -s enabled=true
```

## Step 5: Fix dave

Complete his profile. Do not touch the profile rule; fill in the value it asks for:

```sh
kcadm update "users/$(user_id dave)" -r inventory -s lastName=Example
```

## Step 6: Prove all three fixes

Request a token for each user again and print only whether an access token came back:

```sh
for user in bob carol dave; do
  printf '%s: ' "$user"
  get_user_token "$user" "$user-password" | jq -r 'if .access_token then "token" else .error_description end'
done
```

Each line now says `token`.

## Step 7: Submit

Send the lab for grading:

```sh
astrona submit -c sections/section-010/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Delete and recreate the three users | they get new IDs, and the grader rejects it; in real life you lose their sessions, groups and audit trail |
| Remove the `required` rule for `lastName` | `dave` signs in, but every other user may now skip the last name too |
| Disable `VERIFY_PROFILE` or `UPDATE_PASSWORD` for the realm | one user is fixed by turning off a rule for everyone |
| Set a new password for `bob` only | `UPDATE_PASSWORD` is still pending, so the password grant still refuses him |

## Common mistakes

- Reading only `error`, which is `invalid_grant` for every cause.
- Using `get users -q username=...` without `-q exact=true` in a script, and acting on the wrong user.
- Forgetting that `kcadm config credentials` expires; run it again when a command answers `401`.
