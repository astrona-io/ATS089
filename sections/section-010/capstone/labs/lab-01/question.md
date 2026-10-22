# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Users

## Scenario

The warehouse team in the realm `inventory` changes this week. Two people join, and one person leaves. All of them use the command-line tool `inventory-cli`, and the team's members are in the group `warehouse`.

| Change | Username | First name | Last name | Email |
| --- | --- | --- | --- | --- |
| Joins | `erin` | `Erin` | `Lind` | `erin@example.com` |
| Joins | `frank` | `Frank` | `Moss` | `frank@example.com` |
| Leaves | `mallory` | | | |

`mallory` still has open sessions from this morning. The security team wants her access gone, but her account kept for the audit trail.

## Your task

In the realm `inventory` and the namespace `userscapstone-demo`:

1. Create `erin` and `frank` with the names and email addresses in the table. Give each the temporary password `Welcome-2026-Start`, so they must choose their own password at the first sign-in. Make both members of `warehouse`.
2. Offboard `mallory`: she must not be able to get a token, she must not be a member of `warehouse`, and she must have no sessions left.
3. Leave `alice` as she is.

## Constraints

- **Do not delete `mallory`.** The grader compares her ID with the one the lab started with.
- Do not change `alice`, the group `warehouse` itself, or the client `inventory-cli`.
- Do not change the ConfigMap `capstone-baseline`.

## Done when

- `erin` and `frank` exist, are enabled, have the names and email addresses in the table, have a password, must change it at the first sign-in, and are members of `warehouse`.
- `mallory` has her original ID, is disabled, is not a member of `warehouse`, has no sessions, and gets no token.
- `alice` is unchanged, still in `warehouse`, and still gets a token.
