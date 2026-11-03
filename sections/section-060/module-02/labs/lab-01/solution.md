# Solution: Give A Help Desk Least-Privilege Access

Work the task yourself first. Running `astrona submit -c sections/section-060/module-02/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the roles of the help desk, the roles of the auditor and that nobody holds `realm-admin`. It checks them with real tokens.

## Step 1: Set up the helper

```sh
NAMESPACE=admin-delegation-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
```

## Step 2: Assign the roles

```sh
kcadm add-roles -r inventory --uusername helpdesk --cclientid realm-management \
  --rolename query-users --rolename view-users --rolename manage-users
kcadm add-roles -r inventory --uusername auditor --cclientid realm-management \
  --rolename view-events --rolename view-users
```

## Step 3: Prove it with tokens

```sh
admin_token() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- curl -s \
    http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=password -d client_id=admin-cli -d username="$1" -d password="$1-password" \
    | kubectl -n "$NAMESPACE" exec -i deploy/tester -- jq -r '.access_token'
}
api_status() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- curl -s -o /dev/null -w '%{http_code}\n' \
    -X "$2" "http://keycloak:8080/admin/realms/inventory/$3" \
    -H "Authorization: Bearer $(admin_token "$1")" -H 'Content-Type: application/json' ${4:+-d "$4"}
}
api_status helpdesk GET users
api_status helpdesk POST users '{}'
api_status helpdesk GET events
api_status auditor GET events
api_status auditor POST users '{}'
```

Expect `200`, `400`, `403`, `200` and `403`.

## Step 4: Submit

```sh
astrona submit -c sections/section-060/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| `realm-admin` for both | Both accounts can do everything, and the constraint is broken |
| `manage-users` without `query-users` | The help desk cannot search for the user to reset |
| `view-events` for the help desk | The help desk can read events, which the task denies |
| Test as the `master` admin | Every call passes, which proves nothing |
