# Section 030: Authentication Flows, MFA And Passkeys

Signing in is not one check but a sequence of steps: a cookie, a password form, perhaps a one-time code, perhaps a security key. Keycloak calls that sequence an authentication flow, and every realm lets you change it. This section teaches you to read a flow, change it without locking anyone out, make passwords stronger, ask for a second factor only from the users who need it, and prepare a realm for passkeys.

You will work in the realm `inventory`. Most changes are made with `kcadm.sh`, Keycloak's administration command-line tool; a few are easiest to see in a browser through a port-forward.

**Topic covered:** Authentication

## What you will learn

- What an authentication flow is, how executions and their requirements work, and how flows are bound to a realm.
- Why you copy a built-in flow before you change it.
- How a password policy works, and how to prove that it refuses a weak password.
- How one-time passwords (OTP) work, and how to ask for OTP only from users with one role.
- What WebAuthn and passkeys are, and which policy and required action a realm needs for them.
- Why some of this can only be checked by reading the configuration back.

## The learning path

The section has one module. It has a landing page, three short parts, a graded lab right after the part it tests, and a summary. The module has its own playground, and the landing page starts it for you.

### 1. Control How Users Sign In With Flows, OTP And Passkeys

The module starts at its landing page, which also launches the playground. The playground holds the realm `inventory` with the users `alice` and `bob`; `bob` has the realm role `stock-admin`.

1. Authentication Flows, Executions And Requirements
2. Password Policy And One-Time Passwords, followed by the lab **Enforce A Password Policy And Conditional OTP**
3. WebAuthn And Passkeys
4. Summary

## Section capstone: Require A Second Factor For Administrators

The capstone is one graded scenario that combines the whole module. Stock administrators should need a second factor and be able to register a passkey, yet none of that works: the step is switched off, the setup actions are disabled, and the passkey policy is too weak. You repair the flow and the settings without unbinding the flow or locking ordinary users out. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS089.git -c sections/section-030/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-089-capstone-030
```
