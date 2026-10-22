# Solution: Require A Second Factor For Administrators

Work the task yourself first. Running `astrona submit -c sections/section-030/capstone/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks four things: the flow, the two required actions, the passwordless policy, and that `alice` and `bob` still get tokens through the direct grant.

## Step 1: Set up the helpers

```sh
NAMESPACE=flowscapstone-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
in_tester_jq() {
  kubectl -n "$NAMESPACE" exec -i deploy/tester -- jq "$@"
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
```

## Step 2: Read the flow

```sh
kcadm get realms/inventory --fields browserFlow,directGrantFlow
kcadm get authentication/flows/browser-stock-admin-otp/executions -r inventory \
  --fields displayName,providerId,requirement,level,authenticationFlow
```

The flow is still bound, and it still holds `Condition - user role` and the OTP form. But the subflow that holds them, at the level just above the OTP form, has the requirement `DISABLED`. A disabled subflow is skipped, so nobody is asked for OTP.

## Step 3: Switch the subflow back to CONDITIONAL

Find the disabled subflow one level above the OTP form, set its requirement to `CONDITIONAL`, and send it back:

```sh
EXECS="$(kcadm get authentication/flows/browser-stock-admin-otp/executions -r inventory)"
printf '%s' "$EXECS" | in_tester_jq -c '
  . as $all
  | ([$all[] | select(.providerId == "auth-otp-form")][0].level - 1) as $parent_level
  | [$all[] | select(.authenticationFlow == true and .level == $parent_level and .requirement == "DISABLED")][0]
  | .requirement = "CONDITIONAL"' \
  | kcadm update authentication/flows/browser-stock-admin-otp/executions -r inventory -f -
```

Check that the role condition still points at `stock-admin`. Read the configuration ID from the execution, then the configuration:

```sh
CONFIG_ID="$(kcadm get authentication/flows/browser-stock-admin-otp/executions -r inventory \
  | in_tester_jq -r '[.[] | select(.providerId == "conditional-user-role")][0].authenticationConfig')"
kcadm get "authentication/config/$CONFIG_ID" -r inventory
```

The configuration shows `condUserRole` set to `stock-admin`.

## Step 4: Enable the required actions

```sh
kcadm get authentication/required-actions -r inventory --fields alias,enabled
```

`CONFIGURE_TOTP` and `webauthn-register-passwordless` show `enabled` as `false`. Enable both:

```sh
kcadm update authentication/required-actions/CONFIGURE_TOTP -r inventory -s enabled=true
kcadm update authentication/required-actions/webauthn-register-passwordless -r inventory -s enabled=true
```

## Step 5: Require user verification for passkeys

```sh
kcadm get realms/inventory --fields webAuthnPolicyPasswordlessUserVerificationRequirement
kcadm update realms/inventory -s webAuthnPolicyPasswordlessUserVerificationRequirement=required
```

The first command shows `discouraged`; after the update it is `required`.

## Step 6: Prove the password grant still works

```sh
for user in alice bob; do
  printf '%s: ' "$user"
  kubectl -n "$NAMESPACE" exec deploy/tester -- curl -s \
    http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=password -d client_id=inventory-cli -d username="$user" -d password="$user-password" \
    | jq -r 'if .access_token then "token" else .error_description end'
done
```

Both lines say `token`. To see the OTP step, port-forward the Service and sign in as `bob` at `http://localhost:8080/realms/inventory/account/`.

## Step 7: Submit

```sh
astrona submit -c sections/section-030/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Create a new flow and bind it | the faults in the original stay, and the grader checks the original flow's ID |
| Set the subflow to `REQUIRED` | every user is asked for OTP, not only `stock-admin` |
| Bind the built-in `browser` flow | the second factor for administrators is gone altogether |
| Set user verification to `preferred` | a passkey can still be used without proving the owner is present |
