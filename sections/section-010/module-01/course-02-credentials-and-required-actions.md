# Credentials, Temporary Passwords And Required Actions

An administrator creates an account and sends the new user a first password. That password should work once and then be replaced by one only the user knows. Keycloak supports this with temporary passwords and required actions, and the same mechanism explains many "my password does not work" reports. This part shows how passwords and required actions work, and how to read what the token endpoint says when it refuses a user.

## Credentials and passwords

A **credential** is something a user proves who they are with. Keycloak stores several types: a password, a one-time password (OTP) device, or a WebAuthn key. Each user can have more than one, and the administrator can list them without ever seeing a secret value.

Paste the helpers for this part. `kcadm` is Keycloak's administration command-line tool, run inside the Keycloak pod. `user_id` prints the `id` of one user. `get_user_token` asks the realm `inventory` for a token with the password grant from the `tester` pod and prints the JSON response; OAuth 2.1 drops the password grant, and a real application uses the authorization code flow:

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
get_user_token() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- curl -s \
    http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=password -d client_id=inventory-cli -d username="$1" -d password="$2"
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
```

List the credentials of `bob`. The output is a list with one entry of the type `password`, with its creation date and no value:

```sh
kcadm get "users/$(user_id bob)/credentials" -r inventory
```

## Temporary passwords

A **temporary password** is a password the user must replace at the first sign-in. Set one for `bob` with `--temporary`:

```sh
kcadm set-password -r inventory --username bob --new-password bob-password --temporary
```

The password itself is the same, but Keycloak also added the required action `UPDATE_PASSWORD` to `bob`. A **required action** is a task a user must finish at sign-in before Keycloak issues tokens. Read it back, and then try the password grant:

```sh
kcadm get "users/$(user_id bob)" -r inventory --fields requiredActions
get_user_token bob bob-password
```

The first command shows `requiredActions` with the value `UPDATE_PASSWORD`. The second returns no token: the JSON has `error` set to `invalid_grant` and an `error_description` that says the account is not fully set up. The password was right. Keycloak refused because a browser form is waiting for `bob`, and the password grant cannot show it.

## The required actions a realm offers

Keycloak keeps a list of required actions per realm, and each can be enabled or disabled. List them with their state:

```sh
kcadm get authentication/required-actions -r inventory --fields alias,name,enabled
```

You will meet these most often:

| Alias | What the user must do |
| --- | --- |
| `UPDATE_PASSWORD` | Choose a new password |
| `VERIFY_EMAIL` | Click a link sent to their email address |
| `UPDATE_PROFILE` | Review and update their profile |
| `VERIFY_PROFILE` | Fill in attributes the user profile requires but the record lacks |
| `CONFIGURE_TOTP` | Set up a one-time password app |
| `TERMS_AND_CONDITIONS` | Accept the terms (disabled by default) |

An administrator can add a required action to a user at any time, and Keycloak adds some by itself, as `--temporary` just did. `VERIFY_PROFILE` is special: Keycloak checks it at every sign-in and applies it only when the profile is incomplete.

## Fixing the user, not the rule

There are two ways to let `bob` in from the terminal, and only one is right for a test account. Setting a permanent password with `set-password` and then clearing the required action ends the forced change:

```sh
kcadm set-password -r inventory --username bob --new-password bob-password
kcadm update "users/$(user_id bob)" -r inventory -s 'requiredActions=[]'
get_user_token bob bob-password
```

Now the response holds an `access_token`. The wrong way is to disable `UPDATE_PASSWORD` for the whole realm: that lets every user with a temporary password skip the change.

A disabled account fails in the same place with a different description. Disable `bob`, try again, and enable him:

```sh
kcadm update "users/$(user_id bob)" -r inventory -s enabled=false
get_user_token bob bob-password
kcadm update "users/$(user_id bob)" -r inventory -s enabled=true
```

The middle command returns `invalid_grant` again, this time with a description that says the account is disabled. So the `error` field alone never tells the cause; the `error_description` and the user's settings do.

You can now read three reasons a correct password still gets no token: a pending required action, a disabled account and an incomplete profile. The open question is how to manage many users at once, and how to end a user's access when they leave.

## Your mission: Get Three Users Signed In Again

You can now read why a user gets no token and fix the user without loosening the realm's rules. The graded lab gives you three users who all type the right password and all get refused, each for a different reason, and asks you to get all three signed in without recreating anyone.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-089-playground-010-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS089.git -c sections/section-010/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-089-lab-010-01
astrona start ats-089-playground-010-01
```

## Common pitfalls

> [!WARNING]
> - **Reading only the `error` field.** `invalid_grant` covers a wrong password, a disabled user and a pending required action. Read `error_description`.
> - **Disabling a required action for the realm to fix one user.** That changes the rule for everyone. Clear the action on the one user instead.
> - **Setting a new password and forgetting the required action.** A user who still has `UPDATE_PASSWORD` is still refused on the password grant.
> - **Deleting and recreating a user.** The new user has a new `id`, so every link to the old one (sessions, group history, audit events, linked accounts) is lost.
