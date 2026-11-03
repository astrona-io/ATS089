# Summary

A role is a named permission that an API reads from the access token. Every access decision depends on which roles reach the token, and from where.

## What you learned

Keycloak has two kinds of role. A realm role is defined for the whole realm and suits a job title. A client role is defined by one client and suits a permission that only one API understands. A role mapping links a user or a group to a role. Realm roles appear in the token's `realm_access.roles` claim, and client roles in `resource_access`, under the ID of the client that owns them.

A composite role contains other roles, and a user mapped to it holds all of them; Keycloak expands composites when it builds the token. Every realm has the composite `default-roles-<realm>`, which Keycloak maps to every user, new and existing, so a change to it reaches everyone.

Roles mapped to a group apply to every member and to the members of its subgroups. The difference between a user's direct mappings and their effective roles shows which roles came from groups and composites. Finally, the client that requests the token must let the roles in: the default client scope `roles` holds the protocol mappers that write `realm_access` and `resource_access`, and the setting Full scope allowed decides whether every role or only the client's scope mappings may enter.

- Map roles to groups, not to users.
- Check effective roles, not only direct mappings.
- A correct mapping still needs the client scope `roles` on the client.

<!-- astrona:playground:destroy -->
