# Question

Solve this question on: `terminal`

**Time:** about 35 minutes · **Topic:** Roles and groups

## Scenario

The realm `inventory` has a role model that someone changed in a hurry. The inventory API checks the client roles `stock-read` and `stock-write` of the client `inventory-api`, and three complaints came in:

- `alice`, a warehouse clerk, can list stock but cannot change it.
- `bob`, an auditor, can change stock, though auditors may only read it.
- The API team says tokens from the client `inventory-cli` now carry no roles at all.

The intended model is simple. The group `warehouse` gets the realm role `warehouse-clerk`, which contains `stock-read` and `stock-write`. The group `auditors` gets `stock-read` only. `alice` is in `warehouse` and `bob` is in `auditors`.

## Your task

In the realm `inventory` and the namespace `rolescapstone-demo`:

1. Find every fault. Use access tokens for `alice` (password `alice-password`) and `bob` (password `bob-password`) from `inventory-cli`, the role mappings of the groups, the composite role, and the client scopes of `inventory-cli`.
2. Repair the model so the tokens match the intended model.

The password grant is used here only so you can test from a terminal.

## Constraints

- **Repair the objects that exist.** Do not delete or recreate the groups `warehouse` and `auditors` or the role `warehouse-clerk`. The grader compares their IDs with the ones the lab started with.
- Do not map any of these roles to `alice` or `bob` directly.
- Do not turn off Full scope allowed on `inventory-cli`, and do not change the client roles of `inventory-api`.
- Do not change the ConfigMap `capstone-baseline`.

## Done when

- `alice`'s access token lists `warehouse-clerk`, and `stock-read` and `stock-write` for `inventory-api`.
- `bob`'s access token lists exactly `stock-read` for `inventory-api`.
- `roles` is a default client scope of `inventory-cli`.
- The groups and the role are the originals, and no role is mapped to `alice` or `bob` directly.
