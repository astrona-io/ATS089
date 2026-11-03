# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Delegated administration

## Scenario

The `outpost` company wants a help desk that resets user passwords and an auditor who reads events. Today nobody has a role in the realm `inventory`, and the team lead is tempted to give both of them `realm-admin`. Security wants the smallest set of roles that does each job. Everything runs in the namespace `admin-delegation-demo`.

## Your task

In the realm `inventory`, assign client roles of the client `realm-management`:

1. Give `helpdesk` the roles `query-users`, `view-users` and `manage-users`.
2. Give `auditor` the roles `view-events` and `view-users`.

## Constraints

- Do not give `realm-admin` to anyone.
- Do not give `helpdesk` any events role, and do not give `auditor` any manage role.
- Do not change `alice` or `bob`.

## Done when

- `helpdesk` can list users and is allowed to create users, but cannot read events.
- `auditor` can read events and list users, but cannot create users.
- Neither account holds `realm-admin`.
