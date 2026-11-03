# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Organizations

## Scenario

The `outpost` team serves two customers from the realm `inventory`: Acme and Globex. Today every user sits in one flat list. Management wants the customers separated by organization, with `alice` working for Acme and `bob` working for Globex. Everything runs in the namespace `orgs-demo`.

## Your task

In the realm `inventory`:

1. Turn organizations on.
2. Create the organization with the name `Acme Corporation` and the alias `acme`, and the organization with the name `Globex` and the alias `globex`. Both are enabled.
3. Give `acme` the domain `acme.example` and `globex` the domain `globex.example`.
4. Add `alice` as a member of `acme` and `bob` as a member of `globex`.

## Constraints

- Do not delete or recreate the users.
- Do not add a user to the wrong organization.
- Do not use a wildcard domain.

## Done when

- `organizationsEnabled` is `true` and both organizations exist and are enabled.
- Each organization has its own domain.
- `alice` is a member of `acme` only, and `bob` is a member of `globex` only.
