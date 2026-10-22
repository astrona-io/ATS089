# ATS089 — Realm Administration & Identity Management (Keycloak)

Course material for the **Realm Administration & Identity Management** domain
of the Astrona Keycloak training path ([ATP018](https://github.com/astrona-io/ATP018)),
which is **20% of the path**. Written for **Keycloak 26.8.1**.

> **Status: draft, not yet run.** Every page, playground and lab was written
> from the Keycloak 26.8.1 documentation. None has been started on a cluster,
> and no lab has passed `astrona test` yet. See `CLAUDE.md`.

The course opens with an Introduction in `sections/intro/` (welcome, machine setup,
how the course is made). Everything else lives under `sections/`. Each section
contains:

- **Modules** — a reading chapter split into a short landing page, ordered
  deep-dive parts and a summary page, a throwaway **playground** to explore in,
  and a graded **lab** placed right after the part it tests.
- **A capstone** — one larger graded lab combining that section's modules into a
  single scenario with several independent faults.

---

## Sections

| Section | Title | Modules | Labs | Topic |
| --- | --- | --- | --- | --- |
| [010](sections/section-010) | Users And The User Lifecycle | 1 | 1 + capstone | Users |
| [020](sections/section-020) | Roles, Composite Roles And Groups | 1 | 1 + capstone | Roles and groups |
| [030](sections/section-030) | Authentication Flows, MFA And Passkeys | 1 | 1 + capstone | Authentication |
| [040](sections/section-040) | User Federation And Identity Brokering | 2 | 2 + capstone | Federation and brokering |

The order follows one user through a realm: who they are, what they may do,
how they prove who they are, and finally users who live outside Keycloak.

---

## Modules

| Module | Reader | Parts | Labs |
| --- | --- | --- | --- |
| 010-01 | [Manage Users Through Their Whole Lifecycle](sections/section-010/module-01/course.md) | 3 | [lab-01](sections/section-010/module-01/labs/lab-01) |
| 020-01 | [Model Access With Roles, Composite Roles And Groups](sections/section-020/module-01/course.md) | 3 | [lab-01](sections/section-020/module-01/labs/lab-01) |
| 030-01 | [Control How Users Sign In With Flows, OTP And Passkeys](sections/section-030/module-01/course.md) | 3 | [lab-01](sections/section-030/module-01/labs/lab-01) |
| 040-01 | [Federate Users From An LDAP Directory](sections/section-040/module-01/course.md) | 3 | [lab-01](sections/section-040/module-01/labs/lab-01) |
| 040-02 | [Sign Users In Through Another Identity Provider](sections/section-040/module-02/course.md) | 2 | [lab-01](sections/section-040/module-02/labs/lab-01) |

---

## Capstones

| Capstone | Scenario | Faults |
| --- | --- | --- |
| [010](sections/section-010/capstone/labs/lab-01) | Onboard And Offboard Users With kcadm.sh | two users to create, one leaver with open sessions |
| [020](sections/section-020/capstone/labs/lab-01) | Repair A Broken Role Model | an incomplete composite role, a wrong group mapping, a missing client scope |
| [030](sections/section-030/capstone/labs/lab-01) | Require A Second Factor For Administrators | a disabled conditional subflow, disabled required actions, a weak passkey policy |
| [040](sections/section-040/capstone/labs/lab-01) | Fix A Federation That Lost Its Users | a stale bind credential, a wrong users DN, no group mapper |

---

## The lab environment

Every playground and lab is a **kind** cluster with Keycloak 26.8.1 deployed
from plain Kubernetes manifests in development mode, a `tester` pod with `curl`
and `jq`, and, in section 040, OpenLDAP (`osixia/openldap:1.5.0`) seeded from a
ConfigMap. The bootstrap creates the realm `inventory` and the module's
starting objects with `kcadm.sh`. Credentials are lab-only: `admin` / `admin`
for the `master` realm, `<user>-password` for the example users.

Most labs are proved with a real token request from `tester`. Section 030
cannot register an OTP device or a passkey from a script, so its graders read
the flow, the required actions and the policies back from the Admin REST API.

## Running a playground

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS089.git -c sections/<section>/<module>/playground
astrona destroy <name>
```

## Running a lab

Labs and capstones are graded. Read `question.md`, do the work, and submit:

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS089.git -c sections/<section>/<module>/labs/lab-01
astrona submit -c sections/<section>/<module>/labs/lab-01
astrona destroy <name>
```

Each lab grades the **final state** with independent checks, and several of
them deliberately reject the plausible-but-wrong fix (deleting and recreating
a user, mapping a role straight to a user, editing a built-in flow, switching
LDAP to `WRITABLE`, turning off signature validation).
