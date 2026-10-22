# Summary

User federation lets Keycloak read users from an outside store. With an LDAP directory, the directory stays the source of truth, and Keycloak checks each password by binding to LDAP as the user.

## What you learned

An LDAP directory is a tree of entries, each named by a distinguished name written from the entry up to the base DN. Keycloak binds with a service account to search and binds as the user to check a password. The LDAP provider needs the connection URL, the bind DN and credential, the users DN, the username, RDN and UUID attributes, and the user object classes. The UUID attribute must never change, because it links each Keycloak copy to its entry.

The LDAP provider is one implementation of the User Storage SPI, the Java interface for user stores outside Keycloak's database. In the realm it is a component, created with a `config` map whose values are lists. Keycloak adds default mappers for the username, names and email, which is why directory users arrive with a complete profile. With import on, Keycloak keeps a linked copy of each user, marked with `federationLink`, and a full synchronization copies all users at once.

The edit mode decides who may change a federated user: `READ_ONLY` refuses changes to mapped attributes, `WRITABLE` writes them back to LDAP, and `UNSYNCED` keeps them in Keycloak only. A group mapper turns LDAP groups into Keycloak groups and needs its own synchronization. Periodic full and changed-users synchronizations are off until you set them.

- The directory is the source of truth; change users there.
- Every `config` value of a component is a list.
- Check `federationLink` to know where a user comes from.

<!-- astrona:playground:destroy -->
