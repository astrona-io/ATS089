# Section 010: Users And The User Lifecycle

Every sign-in in Keycloak starts with a user. A user is created, gets a password, signs in, changes jobs, and one day leaves. At each of those steps something can stop the user from getting a token, and the token endpoint only says why in one short error. This section teaches you to read that error, find the setting behind it, and fix the user without breaking anything else.

The section comes first because every later topic, from roles to user federation, ends in a user who either can or cannot sign in. You will work in the realm `inventory`, mostly from the terminal with `kcadm.sh`, Keycloak's administration command-line tool, and you will prove every fix with a real token.

**Topic covered:** Users

## What you will learn

- What a user is in a realm, and what the declarative user profile decides about its attributes.
- Why an administrator cannot create a user without a last name, and why a user without one cannot finish signing in.
- How passwords, temporary passwords and required actions work, and what the token endpoint answers for each.
- How groups collect users, and how to add and remove members.
- How to offboard a user: disable the account, end the sessions, keep the record.
- What administrator impersonation does and who may use it.

## The learning path

The section has one module. It has a landing page, three short parts, a graded lab right after the part it tests, and a summary. The module has its own playground, a cluster where you can explore freely, and the landing page starts it for you.

### 1. Manage Users Through Their Whole Lifecycle

The module starts at its landing page, which also launches the playground. The playground holds the realm `inventory` with the users `alice` and `bob` and the group `warehouse`.

1. Users And The Declarative User Profile
2. Credentials, Temporary Passwords And Required Actions, followed by the lab **Get Three Users Signed In Again**
3. Groups, Disabling Users And Impersonation
4. Summary

## Section capstone: Onboard And Offboard Users With kcadm.sh

The capstone is one graded scenario that combines the whole module. Two people join the warehouse team and one person leaves it. You create the new accounts the way a careful administrator does, with a complete profile, a temporary password and the right group, and you offboard the leaver without deleting the account. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS089.git -c sections/section-010/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-089-capstone-010
```
