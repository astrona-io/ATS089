# Section 020: Roles, Composite Roles And Groups

An API does not ask who a user is; it asks what the user may do. In Keycloak the answer is a set of roles, and the API reads them from the access token. If a role is missing from the token, the API refuses the request, however correct the user's password was. This section teaches you to build roles, combine them, give them to groups, and read exactly which roles reach a token and why.

You will work in the realm `inventory`. The client `inventory-api` stands for the API and defines its own roles, and the client `inventory-cli` requests the tokens. Every change is proved by decoding a real access token.

**Topic covered:** Roles and groups

## What you will learn

- The difference between a realm role and a client role, and when to use each.
- How a composite role bundles other roles, and what the default roles of a realm do.
- How roles mapped to a group reach every member and every subgroup.
- How roles get into the `realm_access` and `resource_access` claims of an access token, through the client scope `roles`.
- How to tell a user's direct role mappings from their effective roles.

## The learning path

The section has one module. It has a landing page, three short parts, a graded lab right after the part it tests, and a summary. The module has its own playground, and the landing page starts it for you.

### 1. Model Access With Roles, Composite Roles And Groups

The module starts at its landing page, which also launches the playground. The playground holds the realm `inventory` with the users `alice` and `bob` and the client `inventory-api`, which defines the client roles `stock-read` and `stock-write`.

1. Realm Roles And Client Roles
2. Composite Roles And Default Roles
3. Group Role Mappings And Roles In Tokens, followed by the lab **Give A Group The Roles Its Members Need**
4. Summary

## Section capstone: Repair A Broken Role Model

The capstone is one graded scenario that combines the whole module. The warehouse staff cannot change stock, the auditors can change it when they should only read it, and no roles at all reach the tokens of `inventory-cli`. You find each fault from the tokens and the role mappings, and repair the role model without replacing it. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS089.git -c sections/section-020/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-089-capstone-020
```
