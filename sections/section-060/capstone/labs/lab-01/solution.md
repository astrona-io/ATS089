# Solution: Delegate Administration Of Organizations

Work the task yourself first. Running `astrona submit -c sections/section-060/capstone/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks four things: the roles of `desk`, the roles of `lead`, the membership of `alice` and `bob`, and that the answers of the Admin API match the roles.

## Step 1: Set up the helper

```sh
NAMESPACE=delegation-capstone
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
kcadm get organizations -r inventory --fields alias
```

## Step 2: Fix the roles

```sh
kcadm remove-roles -r inventory --uusername desk --cclientid realm-management --rolename realm-admin
kcadm add-roles -r inventory --uusername desk --cclientid realm-management \
  --rolename query-organizations --rolename view-organizations --rolename query-users --rolename view-users
kcadm add-roles -r inventory --uusername lead --cclientid realm-management \
  --rolename query-organizations --rolename view-organizations --rolename manage-organizations \
  --rolename query-users --rolename view-users
```

## Step 3: Add alice to acme

```sh
ACME=$(kcadm get organizations -r inventory | kubectl -n "$NAMESPACE" exec -i deploy/tester -- jq -r '.[] | select(.alias=="acme") | .id')
ALICE=$(kcadm get users -r inventory -q username=alice -q exact=true --fields id --format csv --noquotes | tr -d '\r')
kcadm create "organizations/$ACME/members" -r inventory -b "\"$ALICE\""
```

## Step 4: Prove it with tokens

Request a token for each account from the `admin-cli` client of the realm `inventory` and call `organizations` and `users`, as in the module on delegated administration. A read answers `200`. A `POST` with `{}` answers `403` when the role is missing and `400` when it is allowed. Expect `desk` to get `403` for `POST organizations`, and `lead` to get `400` for `POST organizations` and `403` for `POST users`.

## Step 5: Submit

```sh
astrona submit -c sections/section-060/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Keep `realm-admin` and add roles | `realm-admin` includes every role, so `desk` can still create organizations |
| Give `lead` `realm-admin` | Breaks the constraint: `lead` could create users |
| Delete and recreate `acme` to add `alice` | Breaks the constraint and loses the alias |
| Test as the `master` admin | Every call passes and the delegation is not tested |
