# Summary

A realm can be administered by three kinds of account: the server administrator of the `master` realm, a realm administrator with `realm-admin`, and a delegated administrator with a smaller set of rights. Only the third kind can be limited.

## What you learned

The roles for a realm are client roles of the built-in client `realm-management`. The names follow a pattern: `view-` reads, `manage-` changes and `query-` searches. The role `realm-admin` includes all others. A help desk that resets passwords needs `query-users`, `view-users` and `manage-users`, and an auditor needs `view-events` and `view-users`.

The command `kcadm add-roles --uusername <user> --cclientid realm-management --rolename <role>` assigns roles, and `remove-roles` takes them away. The assigned roles are read from `users/<id>/role-mappings/clients/<client-id>`.

The way to prove a delegation is a token. Request one for the delegated user from the `admin-cli` client of the realm, call the Admin API and read the status. A read that returns `200` and a write with empty data that returns `400` mean the call was allowed. `403` means the role is missing. A token holds the roles of the time it was issued.

Fine-grained admin permissions version 2 define permissions on users, groups, clients, roles and organizations, with independent scopes, so a person can administer part of a resource type. A wide role skips them, and realm administrators are not limited by them.

- Grant the smallest set of roles that does the job.
- Test with the delegated account, never with the `master` admin.
- Use permissions, not roles, to limit a person to part of a resource type.

<!-- astrona:playground:destroy -->
