# Welcome To The Course

This course trains you for the **Realm Administration & Identity Management** part of the Astrona **Keycloak** training path. That part is 20% of the path. This page tells you who the course is for, what you can do at the end, which words and example setup it uses, and how its pages fit together.

## Who this course is for

You know your way around Kubernetes: namespaces, Deployments, Services, `kubectl get` and `kubectl exec`. You know what Keycloak is for, what a realm is, and how a client gets a token from a realm's token endpoint. You do not need to have administered Keycloak before. Each new idea is explained the first time it appears.

## What you can do at the end

Administering a realm means making people able to sign in, with the right access and the right checks, and finding out why when they cannot. So this course does not ask you to remember words. It asks you to change a realm and prove the change with a real token or a real sign-in. The course has four topics, and each one turns into a set of skills you will practise.

The first topic is **the user lifecycle**. You will learn to:

- Read the realm's user profile and explain which attributes it requires, and of whom.
- Find why a user with the right password still gets no token, and fix the user.
- Onboard users with temporary passwords and groups, and offboard them without deleting them.

Users need access, so the second topic is **roles and groups**. You will learn to:

- Create realm roles, client roles and composite roles.
- Give roles to a group, so every member gets them.
- Read exactly which roles reach an access token, and why.

The third topic is **authentication flows, multi-factor authentication (MFA) and passkeys**. You will learn to:

- Read and copy an authentication flow, and bind it to the realm.
- Set a password policy and require a one-time password only for one role.
- Prepare a realm for passkeys with the WebAuthn passwordless policy.

The fourth topic is **user federation and identity brokering**. You will learn to:

- Connect Keycloak to an LDAP directory, read-only, with its users and groups.
- Add another realm as an OpenID Connect identity provider, with a role mapper.

Everything is written for **Keycloak 26.8.1**.

## The words this course uses

The pages use Keycloak's own terms, because those are the words you meet in the Admin Console, the logs and the documentation. Each term gets a short, plain definition the first time it appears on a page. A few terms come back on almost every page, so here they are up front.

A **realm** is a space in Keycloak that holds its own users, clients, roles, groups and settings. A **user** is an account in one realm, and a **client** is an application that asks Keycloak to sign users in or to issue tokens. A **role** is a named permission that Keycloak writes into the access token, and a **group** is a set of users that share roles. An **authentication flow** is the ordered set of steps Keycloak runs when a user signs in.

Most commands in the course use `kcadm.sh`, Keycloak's administration command-line tool. It ships inside the Keycloak container image and calls the same Admin REST API the Admin Console uses:

| Command shape | What it does |
| --- | --- |
| `kcadm get <path>` | Reads an object or a list |
| `kcadm create <path> -s field=value` | Creates an object |
| `kcadm update <path> -s field=value` | Changes fields of an object |
| `kcadm delete <path>` | Deletes an object |

## The example setup in your playground

Every playground and lab runs the same small setup. One Keycloak pod, behind the Service `keycloak`, answers on port `8080`. You send your token requests from the `tester` pod, a client with `curl` and `jq`. In the last section, an OpenLDAP pod holds a small company directory.

Inside Keycloak, the pages use the same names everywhere. The application realm is `inventory`, and its users include `alice` and `bob`. The client `inventory-cli` requests tokens from the terminal, and the client `inventory-api` stands for the API and defines the client roles `stock-read` and `stock-write`. In the last section, a second realm, `partner`, acts as an identity provider.

Each module puts this setup in its own namespace, for example `users-demo` or `ldap-demo`, so the pages always tell you the namespace to use. Many labs start with something broken on purpose. That is the material, not a fault in the course.

## How the course is laid out

The course has four sections. It starts with the user, then what the user may do, then how the user signs in, and ends with users who live outside Keycloak.

| Section | What it covers |
| --- | --- |
| 010 | Users And The User Lifecycle |
| 020 | Roles, Composite Roles And Groups |
| 030 | Authentication Flows, MFA And Passkeys |
| 040 | User Federation And Identity Brokering |

Each section has one or more **modules**, and each module teaches one skill. A module brings together four kinds of material:

| What | What it is for | Graded? |
| --- | --- | --- |
| **Reading** | A short landing page, a few chapters that teach one idea each, and a summary | No |
| **Playground** | A small cluster on your own machine, to try everything you read | No |
| **Lab** | A cluster in a starting state, a task, and a grader that checks your work | Yes |
| **Capstone** | The last lab in a section, with several faults at once | Yes |

The best order is simple: read the chapters with the playground open next to them, take each lab when a chapter sends you to it, and finish each section with its capstone. The next part of this page explains how a module's pages guide you through that order.

## How to read a page

A module starts with a **landing page**. It says what the module teaches, what you should know first, and the order of its chapters. At the bottom of the landing page you start the module's playground, and you keep it running while you read.

The chapters (the parts of a module) read like the chapters of a technical book. Each one opens with the problem it solves, explains one idea in connected paragraphs, and closes with what you now know. The hands-on steps sit right in the text: a sentence or two on what to run and why, the command, and then what the result shows. Run each step in your playground as you reach it. You learn more from one real result than from a page of text.

Every chapter ends with a box of common pitfalls, the mistakes people make most often with what the chapter taught, and how to spot them. Now and then a page also has a tip box with a habit or shortcut you can use again, well beyond that page. The two boxes look like this:

> [!TIP]
> **A tip.** A habit or shortcut you can use again, well beyond this one page.

> [!WARNING]
> **Common pitfalls.** The mistakes people make most often with what you just learned, and how to spot them. Every chapter ends with one.

When a graded lab tests what a chapter taught, that chapter ends with a **Your mission** section. It tells you what the lab asks, then gives every command you need, in order: pause the playground with `astrona stop`, start the lab with `astrona run`, and send your work for grading with `astrona submit`. Solve the lab on your own before you look at its solution. When the lab is done, remove it with `astrona destroy` and start the playground again with `astrona start`, so you can carry on reading where you left off.

The last page of every module is the **Summary**. It sums up what you learned in a few short paragraphs, organised by idea. It also ends the module's hands-on work: the Summary page removes the playground, so your machine is clean before the next module.

One rule holds on every page. Code blocks are exactly what you type. Never change a command to make it "look right". If the result is different from what the page describes, that difference is the lesson.
