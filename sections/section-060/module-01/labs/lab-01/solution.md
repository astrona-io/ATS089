# Solution: Create Organizations And Add Members

Work the task yourself first. Running `astrona submit -c sections/section-060/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the realm switch, the organizations with their domains and the memberships.

## Step 1: Set up the helper

```sh
NAMESPACE=orgs-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
```

## Step 2: Turn on organizations and create both

```sh
kcadm update realms/inventory -s organizationsEnabled=true
kcadm create organizations -r inventory -s name="Acme Corporation" -s alias=acme -s enabled=true \
  -s 'domains=[{"name":"acme.example"}]'
kcadm create organizations -r inventory -s name=Globex -s alias=globex -s enabled=true \
  -s 'domains=[{"name":"globex.example"}]'
```

## Step 3: Add the members

```sh
org_id() { kcadm get organizations -r inventory | kubectl -n "$NAMESPACE" exec -i deploy/tester -- jq -r --arg a "$1" '.[] | select(.alias==$a) | .id'; }
user_id() { kcadm get users -r inventory -q username="$1" -q exact=true --fields id --format csv --noquotes | tr -d '\r'; }
kcadm create "organizations/$(org_id acme)/members" -r inventory -b "\"$(user_id alice)\""
kcadm create "organizations/$(org_id globex)/members" -r inventory -b "\"$(user_id bob)\""
```

## Step 4: Check the result

```sh
kcadm get "organizations/$(org_id acme)/members" -r inventory --fields username
kcadm get "organizations/$(org_id globex)/members" -r inventory --fields username
```

## Step 5: Submit

```sh
astrona submit -c sections/section-060/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Create the organizations before turning the feature on | The call is refused |
| Use `*.acme.example` | The task forbids a wildcard domain |
| Put both users in one organization | The membership check fails for the other |
| Delete and recreate the users | Breaks the constraint |
