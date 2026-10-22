# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Roles and groups

## Scenario

The inventory API checks two client roles of the client `inventory-api`: `stock-read` to list stock and `stock-write` to change it. Warehouse staff need both. The team wants one role that stands for the job, and one group that gives it to every member, so that a new clerk gets the right access by joining the group.

`alice` is the first warehouse clerk. Today her access token carries neither role.

## Your task

In the realm `inventory` and the namespace `roles-demo`:

1. Create the realm role `warehouse-clerk` as a composite role that contains the `inventory-api` client roles `stock-read` and `stock-write`.
2. Create the group `warehouse` and map `warehouse-clerk` to it.
3. Make `alice` a member of `warehouse`.
4. Prove it: an access token for `alice` from the client `inventory-cli` must list `warehouse-clerk` in `realm_access` and `stock-read` and `stock-write` for `inventory-api` in `resource_access`.

Get a token for `alice` from the `tester` pod with the password grant (password `alice-password`). The password grant is used here only so you can test from a terminal.

## Constraints

- **Map roles to the group only.** Do not map `warehouse-clerk`, `stock-read` or `stock-write` to `alice` directly.
- Do not change the client `inventory-api` or its client roles.

## Done when

- `alice`'s access token lists `warehouse-clerk` in `realm_access.roles` and `stock-read` and `stock-write` in `resource_access.inventory-api.roles`.
- `warehouse-clerk` is a composite role containing exactly the two client roles.
- `warehouse` maps `warehouse-clerk`, `alice` is a member, and no role is mapped to `alice` directly for this.
