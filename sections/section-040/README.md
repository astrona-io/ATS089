# Section 040: User Federation And Identity Brokering

Many organisations already keep their users somewhere else: in an LDAP directory or Active Directory, or with another identity provider such as a partner's Keycloak, GitHub or Google. Keycloak does not have to copy those users by hand. It can read them from a directory, which is user federation, or send them to another identity provider to sign in, which is identity brokering. This section teaches both.

You will connect the realm `inventory` to an OpenLDAP directory that runs in the cluster, and you will make a second realm, `partner`, act as an OpenID Connect identity provider for `inventory`. Each setup is proved with a real sign-in or with the settings read back.

**Topic covered:** Federation and brokering

## What you will learn

- What user federation is, and how the LDAP provider uses the User Storage SPI.
- How to connect Keycloak to an LDAP directory: connection URL, bind DN, users DN and the user attributes.
- What the edit modes `READ_ONLY`, `WRITABLE` and `UNSYNCED` do, and how mappers and synchronization work.
- What identity brokering is, how it differs from federation, and how social login fits in.
- How to add an OpenID Connect identity provider, with its client, its mappers and the first broker login flow.

## The learning path

The section has two modules. Each has a landing page, short parts, a graded lab right after the part it tests, and a summary. Each module has its own playground, and its landing page starts it for you.

### 1. Federate Users From An LDAP Directory

The playground holds the realm `inventory` and an OpenLDAP server with the users `ldap-ana` and `ldap-ben` and the group `warehouse`.

1. LDAP Federation And The User Storage SPI
2. Connecting Keycloak To OpenLDAP, followed by the lab **Federate An LDAP Directory**
3. Edit Modes, Mappers And Synchronization
4. Summary

### 2. Sign Users In Through Another Identity Provider

The playground holds the realms `inventory` and `partner`, the user `pat` in `partner`, and the client `inventory-broker` that `inventory` uses to talk to `partner`.

1. Identity Brokering And Social Login
2. Adding An OpenID Connect Identity Provider, followed by the lab **Broker Sign-In From A Partner Realm**
3. Summary

## Section capstone: Fix A Federation That Lost Its Users

The capstone is one graded scenario built on LDAP federation. After a directory change, no LDAP user can sign in, and the team's LDAP group never shows up in Keycloak. You find the faults in the provider's settings, repair the provider without deleting it, and add the group mapper. Work it after the module labs.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS089.git -c sections/section-040/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-040/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-089-capstone-040
```
