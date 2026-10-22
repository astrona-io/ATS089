# Password Policy And One-Time Passwords

Two requests from the security review are on the table: every new password must be at least twelve characters with a digit, and stock administrators must type a one-time code at sign-in. The first is one realm setting. The second is a change to the browser flow that must affect only the users with the role `stock-admin`. This part does both, and proves the first one from the terminal.

## The password policy

A **password policy** is a list of rules that every new password in the realm must pass. Keycloak checks it whenever a password is set: by the user, by an administrator, or by a reset. Existing passwords are not checked again until they change.

Paste the helpers for this part. `kcadm` runs Keycloak's administration command-line tool inside the Keycloak pod. `in_tester_jq` runs `jq` inside the `tester` pod, for the JSON edits below:

<!-- astrona:playground:renew -->

```sh
NAMESPACE=flows-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
in_tester_jq() {
  kubectl -n "$NAMESPACE" exec -i deploy/tester -- jq "$@"
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
```

The policy is one string of rules joined with `and`. Set a minimum length of twelve and at least one digit:

```sh
kcadm update realms/inventory -s 'passwordPolicy=length(12) and digits(1)'
kcadm get realms/inventory --fields passwordPolicy
```

Some of the rules you can combine:

| Rule | What it requires |
| --- | --- |
| `length(n)` | At least `n` characters |
| `digits(n)` | At least `n` digits |
| `upperCase(n)` / `lowerCase(n)` | At least `n` upper-case / lower-case letters |
| `specialChars(n)` | At least `n` characters that are not letters or digits |
| `notUsername` | Not the same as the username |
| `passwordHistory(n)` | Not one of the last `n` passwords |

Now prove the policy works. Setting a short password for `alice` must fail, and a long one with a digit must succeed:

```sh
kcadm set-password -r inventory --username alice --new-password short1
kcadm set-password -r inventory --username alice --new-password alice-password-2026
```

The first command fails with an error that names the policy rule the password broke. The second succeeds, so `alice`'s password is now `alice-password-2026`. Her old password, `alice-password`, has fourteen characters but no digit, so the policy would refuse it now; use the new one from here on.

## One-time passwords

A **one-time password (OTP)** is a short code from an app on the user's phone. With TOTP, the time-based kind, the code changes every period, by default thirty seconds. The **OTP policy** of the realm says how the codes are made. Read it:

```sh
kcadm get realms/inventory --fields otpPolicyType,otpPolicyAlgorithm,otpPolicyDigits,otpPolicyPeriod
```

The defaults are `totp`, `HmacSHA1`, `6` digits and a `30`-second period, which the common authenticator apps support. A user sets up an OTP device through the required action `CONFIGURE_TOTP`, which shows a QR code to scan.

## Asking for OTP only from stock administrators

The built-in second-factor subflow asks for OTP only from users who already have an OTP device, through `Condition - user configured`. The review wants something different: every user with `stock-admin` must use OTP, and nobody else is asked. So in a copy of the browser flow you replace that condition with **`Condition - user role`**, which is true when the user has a given role.

Copy the flow and find the second-factor subflow, the one with the requirement `CONDITIONAL`:

```sh
kcadm create authentication/flows/browser/copy -r inventory -s newName=browser-stock-admin-otp
EXECS="$(kcadm get authentication/flows/browser-stock-admin-otp/executions -r inventory)"
SUBFLOW="$(printf '%s' "$EXECS" | in_tester_jq -r '[.[] | select(.authenticationFlow == true and .requirement == "CONDITIONAL")][0].displayName')"
echo "$SUBFLOW"
```

The last command prints the name of the subflow in your copy. Remove its `Condition - user configured`, and add `Condition - user role` (provider `conditional-user-role`) to it. A flow name with spaces goes into the path with `%20`:

```sh
for EXEC_ID in $(printf '%s' "$EXECS" | in_tester_jq -r '.[] | select(.providerId == "conditional-user-configured") | .id'); do
  kcadm delete "authentication/executions/$EXEC_ID" -r inventory
done
kcadm create "authentication/flows/$(printf '%s' "$SUBFLOW" | sed 's/ /%20/g')/executions/execution" -r inventory -s provider=conditional-user-role
```

A new execution starts as `DISABLED`. Set the condition and the OTP form to `REQUIRED` by sending each execution back with a new requirement, and then tell the condition which role to check. Its setting is called `condUserRole`:

```sh
EXECS="$(kcadm get authentication/flows/browser-stock-admin-otp/executions -r inventory)"
for provider in conditional-user-role auth-otp-form; do
  printf '%s' "$EXECS" | in_tester_jq -c "[.[] | select(.providerId == \"$provider\")][0] | .requirement = \"REQUIRED\"" \
    | kcadm update authentication/flows/browser-stock-admin-otp/executions -r inventory -f -
done
ROLE_EXEC_ID="$(printf '%s' "$EXECS" | in_tester_jq -r '[.[] | select(.providerId == "conditional-user-role")][0].id')"
kcadm create "authentication/executions/$ROLE_EXEC_ID/config" -r inventory \
  -s alias=stock-admin-only -s 'config.condUserRole=stock-admin' -s 'config.negate=false'
```

Check the copy before you bind it. The subflow now holds `Condition - user role` and the OTP form, both `REQUIRED`, and no `Condition - user configured`:

```sh
kcadm get authentication/flows/browser-stock-admin-otp/executions -r inventory --fields displayName,requirement,level
kcadm update realms/inventory -s browserFlow=browser-stock-admin-otp
```

The second command binds the copy as the browser flow. To see it work, run `kubectl -n flows-demo port-forward svc/keycloak 8080:8080` in a second terminal and open `http://localhost:8080/realms/inventory/account/`. Sign in as `bob`: after the password, Keycloak shows the OTP setup page, because `bob` has `stock-admin` and no OTP device yet. Sign in as `alice` in a private window: she goes straight in. The password grant is not affected, because it runs the `direct grant` flow.

You can now make passwords stronger for everyone and add a second factor for exactly one group of users. The open question is the next step beyond a code: a credential that replaces the password altogether.

## Your mission: Enforce A Password Policy And Conditional OTP

You can now set a password policy, prove it, and require OTP for one role in a copied flow. The graded lab gives you a realm with no policy and the built-in browser flow, and asks you to put both requirements of the security review in place without changing how anyone else signs in.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-089-playground-030-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS089.git -c sections/section-030/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-089-lab-030-01
astrona start ats-089-playground-030-01
```

## Common pitfalls

> [!WARNING]
> - **Expecting a policy to check existing passwords.** It checks new passwords only. Existing ones change at the next reset.
> - **Leaving `Condition - user configured` next to the role condition.** All conditions must be true, so a stock administrator without an OTP device is never asked.
> - **Forgetting that new executions start `DISABLED`.** A condition that is disabled never runs.
> - **Binding the copy before the condition has its role.** Without `condUserRole`, the condition matches nobody, or the flow fails, depending on the version.
