# Section 060: Organizations And Administration Delegation

A realm often serves more than one company, team or customer. Keycloak organizations group the users of a realm by customer, and delegated administration lets you hand each customer's contact, a help desk or an auditor only the part of the administration they need. This section teaches both, and it ends with a scenario that combines them.

You will create organizations with `kcadm.sh`, add members, read the organization claim in a token, assign realm-management roles and prove each delegation with a real token and the status code of the Admin API.

**Topic covered:** Organizations and delegated administration

## What you will learn

- How to enable organizations in a realm, and what the name, the alias, the domains and the attributes of an organization are.
- The difference between managed and unmanaged members, and how to add and remove members.
- How the `organization` scope puts an `organization` claim in a token.
- The three kinds of realm administrator and the roles of the client `realm-management`.
- How to give a user the smallest set of roles for a task and prove it with a token.
- What fine-grained admin permissions add to roles, and where their limits are.

## The learning path

The section has two modules. Each has a landing page, short parts, a graded lab right after the part it tests, and a summary. Each module has its own playground, and its landing page starts it for you.

### 1. Group Users Into Organizations

The playground holds the realm `inventory`, the users `alice` and `bob` and the client `inventory-cli`.

1. Enabling And Creating Organizations
2. Domains And Attributes
3. Members, followed by the lab **Create Organizations And Add Members**
4. The Organization Claim
5. Summary

### 2. Delegate Administration With Realm-Management Roles

The playground holds the realm `inventory` and the users `helpdesk`, `auditor`, `alice` and `bob`, with no administration roles.

1. Who Can Administer A Realm
2. The Realm-Management Roles
3. Proving What An Administrator Can Do, followed by the lab **Give A Help Desk Least-Privilege Access**
4. Fine-Grained Permissions And Limits
5. Summary

## Section capstone: Delegate Administration Of Organizations

The capstone is one graded scenario that joins both modules. Two customers are organizations of the realm. A support person holds `realm-admin` by mistake, the team lead has no rights, and one customer user is missing from her organization. You repair the roles and the membership without deleting anything, and prove the result with tokens. Work it after the module labs.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS089.git -c sections/section-060/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-060/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-089-capstone-060
```
