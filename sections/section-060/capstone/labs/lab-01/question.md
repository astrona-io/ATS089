# Question

Solve this question on: `terminal`

**Time:** about 40 minutes · **Topic:** Organizations and delegated administration

## Scenario

The `outpost` company runs two customers, Acme and Globex, as organizations in the realm `inventory`. The support person `desk` was given `realm-admin` in a hurry, so `desk` can change anything. The team lead `lead` should manage organizations but received nothing. The Acme user `alice` was never added to her organization. Everything runs in the namespace `delegation-capstone`.

## Your task

In the realm `inventory`:

1. Take `realm-admin` away from `desk`. Give `desk` read access only: `query-organizations`, `view-organizations`, `query-users` and `view-users`.
2. Give `lead` the roles `query-organizations`, `view-organizations`, `manage-organizations`, `query-users` and `view-users`.
3. Add `alice` as a member of the organization `acme`.

## Constraints

- Do not delete the organizations or the users.
- Do not move `bob` out of `globex`.
- Do not give `lead` any role that manages users or clients.
- Prove the result with tokens of `desk` and `lead`, not with the `master` admin.

## Done when

- `desk` does not hold `realm-admin`, can list organizations and users, and cannot create an organization.
- `lead` can list organizations and is allowed to create one, and cannot create users.
- `alice` is a member of `acme`, and `bob` is still a member of `globex`.
