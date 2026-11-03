# Fine-Grained Permissions And Limits

Roles apply to a whole resource type: `manage-users` allows changing every user of the realm. When a customer's contact should manage only the users of that customer, roles are too wide. Keycloak has a policy-based feature for that, called fine-grained admin permissions version 2. This part explains what it adds, how it relates to roles and where the limits are.

## What roles cannot express

A role has no condition. A person with `manage-users` can change every user, including the ones in other organizations and the administrators themselves. You cannot say "only the members of this group" with roles alone. That is the gap that fine-grained permissions fill.

## What fine-grained permissions add

The feature defines permissions on resource types: users, groups, clients, roles and organizations. For each type there is a set of scopes, such as `view` and `manage`, plus specific ones such as `reset-password`, `map-roles`, `impersonate` and, on groups, `view-members` and `manage-members`. A permission ties scopes of a resource type, or of chosen resources, to a policy that says who may use it. The scopes are independent: `manage` does not include `view`.

Delegating the users of one group means giving a person `view-members` and `manage-members` on that group, and `view` on the group itself so it can be found. The person can then see and change those users and no others. Combined with groups, this is how a delegated administrator for one customer is built.

You turn the feature on in the realm settings, and you define permissions in the Admin Console. This module does not run these steps from the terminal, because they involve the authorization services of a generated client and you should read the screens.

## How it relates to roles

The feature is an alternative to roles, not a replacement. If you also grant a role such as `view-users` or `manage-clients`, that role works as before and skips the fine-grained check. So a delegated administrator who must stay limited has to hold no wide role for the same resource. Server administrators and realm administrators are never limited by these permissions.

## Limits to remember

Enforcement applies to the Admin Console and the Admin API only. Users from an LDAP provider with import turned off are not stored in the database and do not appear in searches that are limited by permissions. If such users must be found, give the administrator the `view-users` role. A permission on one resource does not override a deny on a group of members: a deny on a group stops access to its members unless the group itself gets an explicit allow.

## A decision rule

Use roles when the person administers a whole kind of resource, such as all users or all events. Use fine-grained permissions when the person administers a part, such as the members of one group. Whichever you use, test it with a token for that person, as in the previous part.

You now have the full range of delegation: roles for wide rights, permissions for narrow ones and tokens to prove them.

## Common pitfalls

> [!WARNING]
> - **Mixing a wide role with a narrow permission.** The role wins, so the limit is not enforced.
> - **Assuming `manage` includes `view`.** Scopes are independent, so grant both.
> - **Limiting a realm administrator.** A holder of `realm-admin` is never limited by permissions.
> - **Expecting limited search to include imported-off LDAP users.** They are not in the database.
