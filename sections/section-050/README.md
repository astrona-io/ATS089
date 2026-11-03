# Section 050: Realm Settings, Sessions And Auditing

A realm has settings that shape what users see when they sign in, how long they stay signed in and what the server remembers about it. Most support calls about Keycloak come from these settings: a missing Forgot Password link, a user who is signed out too early, a token that expires before a job finishes, or a question that nobody can answer because events were never turned on. This section teaches the settings and how to read their effect.

You will change the realm `inventory` with `kcadm.sh` and prove each change with a real request, such as a token whose `exp` and `iat` you read, or an event you list.

**Topic covered:** Realm settings, sessions and events

## What you will learn

- Which realm fields control registration, password reset, remember me, email login and email verification, and how to set up email, languages and themes.
- How to read and change the realm representation, and which changes are safe in a running realm.
- How the SSO session limits, the access token lifespan and the offline session limits work, and how to override a lifespan for one client.
- How to list, end and revoke sessions, including offline sessions.
- How to turn on user events and admin events, read them with filters and find the cause of a failed sign-in.

## The learning path

The section has three modules. Each has a landing page, short parts, a graded lab right after the part it tests, and a summary. Each module has its own playground, and its landing page starts it for you.

### 1. Configure Login, Email And Display Settings Of A Realm

The playground holds the realm `inventory` with a few users and the settings to change.

1. Login Options Of A Realm
2. Email Settings And Verification
3. Localization And Themes, followed by the lab
4. Reading And Changing The Realm Representation
5. Summary

### 2. Control Sessions, Token Lifespans And Offline Access

The playground holds the realm `inventory`, the users `alice` and `bob` and the clients `inventory-cli` and `inventory-batch`.

1. SSO Session Settings
2. Token Lifespans
3. Offline Tokens, followed by the lab
4. Administering Sessions
5. Summary

### 3. Record And Read Events And Admin Events

The playground holds the realm `inventory`, the user `alice` and the client `inventory-cli`, with events off.

1. User Events
2. Admin Events
3. Finding A Failed Sign-In, followed by the lab
4. Retention, Listeners And Server Logs
5. Summary

## Section capstone: Fix A Realm That Locks Users Out

The capstone is one graded scenario with three independent faults. Users are signed out within two minutes, their tokens last ten seconds, nobody can reset a password, and `bob` cannot sign in for a reason that nobody knows because events are off. You turn on events, read the cause, and repair the realm without recreating it. Work it after the module labs.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS089.git -c sections/section-050/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-050/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-089-capstone-050
```
