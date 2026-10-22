# Solution: Give A Group The Roles Its Members Need

Work the task yourself first. Running `astrona submit -c sections/section-020/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the roles in `alice`'s token, the composite role, and that the roles reach `alice` through the group.

## Step 1: Set up the helpers

`kcadm` runs Keycloak's administration command-line tool in the Keycloak pod. `get_access_token` prints an access token from the password grant, and `decode_token` prints its claims:

```sh
NAMESPACE=roles-demo
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
```

Look at `alice`'s token before you change anything. `resource_access` has no entry for `inventory-api`:

```sh
get_access_token alice alice-password | decode_token | jq '{realm_access, resource_access}'
```

## Step 2: Build the composite role

Create the realm role, then add the two client roles to it. `--rname` names the role that receives the others, and `--cclientid` names the client that owns them:

```sh
kcadm create roles -r inventory -s name=warehouse-clerk -s 'description=Warehouse staff: read and change stock'
kcadm add-roles -r inventory --rname warehouse-clerk --cclientid inventory-api \
  --rolename stock-read --rolename stock-write
kcadm get roles/warehouse-clerk/composites -r inventory --fields name,clientRole
```

The last command lists `stock-read` and `stock-write`, both client roles.

## Step 3: Create the group and map the role to it

```sh
kcadm create groups -r inventory -s name=warehouse
kcadm add-roles -r inventory --gname warehouse --rolename warehouse-clerk
```

## Step 4: Add alice to the group

Look up both IDs and create the membership:

```sh
ALICE_ID="$(kcadm get users -r inventory -q username=alice -q exact=true --fields id --format csv --noquotes | tr -d '\r')"
GROUP_ID="$(kcadm get groups -r inventory -q search=warehouse --fields id,name --format csv --noquotes | tr -d '\r' | awk -F, '$2 == "warehouse" {print $1}')"
kcadm update "users/$ALICE_ID/groups/$GROUP_ID" -r inventory -s realm=inventory -s userId="$ALICE_ID" -s groupId="$GROUP_ID" -n
```

## Step 5: Prove it

Compare `alice`'s direct mappings with her effective roles, then read a fresh token:

```sh
kcadm get-roles -r inventory --uusername alice
kcadm get-roles -r inventory --uusername alice --effective
get_access_token alice alice-password | decode_token | jq '{realm_access, resource_access}'
```

The direct list holds only `default-roles-inventory`. The effective list adds `warehouse-clerk`. The token lists `warehouse-clerk` in `realm_access.roles` and `stock-read` and `stock-write` under `resource_access.inventory-api.roles`.

## Step 6: Submit

```sh
astrona submit -c sections/section-020/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Map `stock-read` and `stock-write` to `alice` | her token is right, but the next clerk gets nothing; the grader rejects direct mappings |
| Add the client roles to `default-roles-inventory` | every user in the realm can now change stock |
| Make `warehouse-clerk` a client role of `inventory-cli` | the job title is tied to one client, and other clients cannot see it as a realm role |
