# Solution: Repair A Broken Role Model

Work the task yourself first. Running `astrona submit -c sections/section-020/capstone/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks four things: `alice`'s token, `bob`'s token, the client scope `roles` on `inventory-cli`, and that the original groups and role were repaired, not replaced.

## Step 1: Set up the helpers and read the tokens

```sh
NAMESPACE=rolescapstone-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
get_access_token() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- curl -s \
    http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=password -d client_id=inventory-cli -d username="$1" -d password="$2" \
    | jq -r .access_token
}
decode_token() {
  jq -R 'split(".")[1] | gsub("-";"+") | gsub("_";"/") | . + ("=" * ((4 - length % 4) % 4)) | @base64d | fromjson'
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
get_access_token alice alice-password | decode_token | jq '{realm_access, resource_access}'
```

Both claims are missing from the token: the result shows `null` for each. That is the API team's complaint, and it hides the other two faults, so start with the client.

## Step 2: Find and fix the client scope

List the default client scopes of `inventory-cli`:

```sh
CLI_ID="$(kcadm get clients -r inventory -q clientId=inventory-cli --fields id --format csv --noquotes | tr -d '\r')"
kcadm get "clients/$CLI_ID/default-client-scopes" -r inventory --fields name
```

`roles` is not in the list, so no protocol mapper writes `realm_access` or `resource_access`. Look up the scope's ID and add it back as a default scope. The `-n` option sends the request without reading the path first:

```sh
ROLES_SCOPE_ID="$(kcadm get client-scopes -r inventory --fields id,name --format csv --noquotes | tr -d '\r' | awk -F, '$2 == "roles" {print $1}')"
kcadm update "clients/$CLI_ID/default-client-scopes/$ROLES_SCOPE_ID" -r inventory -n
```

Read both tokens again:

```sh
get_access_token alice alice-password | decode_token | jq '.resource_access["inventory-api"]'
get_access_token bob bob-password | decode_token | jq '.resource_access["inventory-api"]'
```

Now the roles show, and the two other faults with them: `alice` has only `stock-read`, and `bob` has `stock-write`.

## Step 3: Fix the composite role

```sh
kcadm get roles/warehouse-clerk/composites -r inventory --fields name
```

`warehouse-clerk` contains only `stock-read`. Add `stock-write`:

```sh
kcadm add-roles -r inventory --rname warehouse-clerk --cclientid inventory-api --rolename stock-write
```

## Step 4: Fix the auditors group

```sh
kcadm get-roles -r inventory --gname auditors --cclientid inventory-api
```

The group maps `stock-write`. Replace it with `stock-read`:

```sh
kcadm remove-roles -r inventory --gname auditors --cclientid inventory-api --rolename stock-write
kcadm add-roles -r inventory --gname auditors --cclientid inventory-api --rolename stock-read
```

## Step 5: Prove it

```sh
get_access_token alice alice-password | decode_token | jq '{realm: .realm_access.roles, api: .resource_access["inventory-api"].roles}'
get_access_token bob bob-password | decode_token | jq '{api: .resource_access["inventory-api"].roles}'
```

`alice`'s token lists `warehouse-clerk` and both client roles. `bob`'s token lists only `stock-read` for `inventory-api`.

## Step 6: Submit

```sh
astrona submit -c sections/section-020/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Map `stock-write` to `alice` directly | her token is right, but the next clerk is still missing it; the grader rejects direct mappings |
| Delete and recreate `warehouse-clerk` | a new role ID; anything that referenced the old role breaks, and the grader rejects it |
| Turn off Full scope allowed to hide `stock-write` from `bob` | `alice` loses her roles too, and the real fault in `auditors` stays |
