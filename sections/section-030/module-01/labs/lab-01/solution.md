# Solution: Enforce A Password Policy And Conditional OTP

Work the task yourself first. Running `astrona submit -c sections/section-030/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the password policy refuses a weak password and accepts a strong one, the new flow asks for OTP only for `stock-admin` and is bound, and `alice` and `bob` still get tokens through the direct grant.

## Step 1: Set up the helpers

`kcadm` runs Keycloak's administration command-line tool in the Keycloak pod. `in_tester_jq` runs `jq` in the `tester` pod for the JSON edits:

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

## Step 2: Set and test the password policy

```sh
kcadm update realms/inventory -s 'passwordPolicy=length(12) and digits(1)'
kcadm get realms/inventory --fields passwordPolicy
```

Test it on a throw-away user, so `alice` and `bob` keep their passwords. The first `set-password` fails with an error that names the broken rule; the second succeeds:

```sh
kcadm create users -r inventory -s username=policy-test -s enabled=true \
  -s email=policy-test@example.com -s firstName=Policy -s lastName=Test
kcadm set-password -r inventory --username policy-test --new-password short1
kcadm set-password -r inventory --username policy-test --new-password long-enough-password-1
kcadm delete "users/$(kcadm get users -r inventory -q username=policy-test -q exact=true --fields id --format csv --noquotes | tr -d '\r')" -r inventory
```

## Step 3: Copy the browser flow

```sh
kcadm create authentication/flows/browser/copy -r inventory -s newName=browser-stock-admin-otp
EXECS="$(kcadm get authentication/flows/browser-stock-admin-otp/executions -r inventory)"
SUBFLOW="$(printf '%s' "$EXECS" | in_tester_jq -r '[.[] | select(.authenticationFlow == true and .requirement == "CONDITIONAL")][0].displayName')"
echo "$SUBFLOW"
```

The last command prints the name of the conditional second-factor subflow in the copy.

## Step 4: Replace the condition

Remove `Condition - user configured`, then add `Condition - user role` to the subflow. Spaces in the subflow name become `%20` in the path:

```sh
for EXEC_ID in $(printf '%s' "$EXECS" | in_tester_jq -r '.[] | select(.providerId == "conditional-user-configured") | .id'); do
  kcadm delete "authentication/executions/$EXEC_ID" -r inventory
done
kcadm create "authentication/flows/$(printf '%s' "$SUBFLOW" | sed 's/ /%20/g')/executions/execution" -r inventory -s provider=conditional-user-role
```

## Step 5: Make the condition and the OTP form REQUIRED, and set the role

A new execution starts `DISABLED`. Send each execution back with the requirement `REQUIRED`, then configure the role condition:

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

Check the copy. The subflow holds `Condition - user role` and the OTP form, both `REQUIRED`:

```sh
kcadm get authentication/flows/browser-stock-admin-otp/executions -r inventory --fields displayName,requirement,level
```

## Step 6: Bind the flow and prove the direct grant still works

```sh
kcadm update realms/inventory -s browserFlow=browser-stock-admin-otp
kcadm get realms/inventory --fields browserFlow,directGrantFlow
for user in alice bob; do
  printf '%s: ' "$user"
  kubectl -n "$NAMESPACE" exec deploy/tester -- curl -s \
    http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=password -d client_id=inventory-cli -d username="$user" -d password="$user-password" \
    | jq -r 'if .access_token then "token" else .error_description end'
done
```

`browserFlow` is `browser-stock-admin-otp`, `directGrantFlow` is still `direct grant`, and both users get a token. To see the OTP step for yourself, port-forward the Service and sign in as `bob` at `http://localhost:8080/realms/inventory/account/` in a browser.

## Step 7: Submit

```sh
astrona submit -c sections/section-030/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Change the built-in `browser` flow | Keycloak refuses changes to built-in flows, and you lose the known-good fallback |
| Keep `Condition - user configured` next to the role condition | both must be true, so a stock administrator without an OTP device is never asked |
| Make the OTP form `REQUIRED` outside the conditional subflow | every user is asked for OTP, not only `stock-admin` |
| Bind the new flow as the direct grant flow | the password grant cannot show an OTP form, so `inventory-cli` stops working |
