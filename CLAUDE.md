# Writing style for this repo

All study text here (course pages, lab docs, READMEs, comments in YAML and
scripts) is for people learning a technical subject, often for a
certification exam. Many of them are not native English speakers and have no
university degree.

## Technical documentation in plain English

This is technical documentation. Say exactly what the system does, with the
real technical terms, in clear and simple English. Never hide a concept
behind a metaphor, a made-up name or a vague word: the reader must learn the
words they will meet in the product, the logs and the exam.

Strict guidelines:

1. Use the correct technical term every time (request, response, pod,
   namespace, Service, sidecar proxy, certificate, mTLS, JWT, listener). The
   first time a term appears in a file, define it in one plain sentence that
   says what it is and what it does. Spell out every acronym on first use.
2. No metaphors or analogies in explanations. Not "the communications
   officer", but "the sidecar proxy (Envoy)"; not "a signal", but "a
   request"; not "the planet", but "the namespace".
3. Simple sentences. Target a Flesch-Kincaid Grade Level of 8 or 9 for the
   prose around the terms. Keep sentences direct; split long sentences into
   two. No corporate buzzwords.
4. Use short paragraphs (max 3-4 sentences per paragraph).
5. Use the active voice ("istiod sends the configuration", not "the
   configuration is sent").

## How this applies to course material

- **Know which file you are in.** A module has a short landing page, a few
  deep-dive parts and a summary page. The landing page is a map: goals, what
  to know first, the order of the parts. The real teaching goes in the parts.
  The summary closes the module. A lab
  has a task, a step-by-step solution and a short intro. Keep each file to its
  job. Do not add "Prerequisite: ... Next: ..." navigation lines to pages;
  the landing page and the course outline already give the order.
- **Keep each part short.** One idea per part, about 5 to 8 minutes of
  reading and at most about 8 command blocks, so a learner can finish it with
  the playground in one sitting of about 15 minutes. Split at a natural seam
  where each half ends with something the learner has seen work. Never split
  only to hit a number. When you split, renumber the files, fix every "Part N"
  reference in the module and `astrona.yaml`.
- **Read like a book, not like a web page.** Each part reads as a chapter of
  a technical book. Open with a short paragraph on the problem it solves and
  why it matters. Link each paragraph to the next with a transition sentence.
  Close with a paragraph that sums up what the reader now knows and the
  question still open, before `## Common pitfalls` and the mission. Write
  explanations as prose; keep bullets for real lists (fields, ordered steps,
  options). Use `##` only when the topic changes and `###` only inside a long
  section, never for a single command. Weave hands-on steps into the text:
  one or two sentences on what to run and why, the command, the real output,
  then a sentence or two on what it shows.
- **The module ends with a summary.** The last page of every module is
  `course-0N-summary.md` with the title `# Summary`: a few short prose
  paragraphs on what the reader learned, organised by idea, optionally with
  one short list of key facts. It names no parts, modules, sections or
  chapters, and has no links, lab table, quiz or commands. Its last line is
  `<!-- astrona:playground:destroy -->` on its own line; the platform turns it
  into the step that removes the playground.
- **Every heading gets an intro.** A `##` section that has `###`
  subsections starts with one to three sentences that say what the section
  is about and why it matters, before the first `###`. Never put a `###`
  directly under a `##`.
- **Every module stands on its own.** Never refer to other sections or
  modules: no "see section 040", "as module 3 showed", "you met this in
  section 000", and no links to pages in another module. If the reader needs
  a fact from elsewhere, state the fact directly in one or two sentences.
  This also goes for parts of the same module: never write "Part 2 shows",
  "from Part 1" or "as in Part 3". Say the fact itself ("the commands below
  need the `scout` `DestinationRule` applied"). This includes the summary.
  The landing page does not have a "Where this fits" section.
- **Write words out in full.** Do not use informal short forms in prose:
  write "communications", "configuration", "repository", "administrator",
  "for example" and "that is", never "comms", "config", "repo", "admin",
  "e.g." or "i.e.". Names in code, commands and file paths stay as they are.
- **Exam terms stay.** The product's own names are what the reader must learn
  (for example a resource kind, a field, a command). Use them as they are and
  define each one in plain technical words the first time it appears in a
  file. Spell out acronyms on first use, with a short plain meaning.
- **The space theme is only for examples.** Space appears in two places and
  nowhere else: the names of the example workloads (the Starfleet: `bridge`,
  `scout`, `shuttle`, `probe`, the `starfleet` and `outpost` namespaces) and
  the short scenario that opens a lab task or a practice exercise (for
  example "the `drifter` in `outpost` must keep reaching the probe"). The
  explanation around an example is plain technical text: write "the
  `shuttle` pod sends a request to the `probe` Service", never "the shuttle
  sends a signal to the probe ship". Do not address the reader as an
  astronaut, and do not use space metaphors (communications officer, mission
  control, badge, airlock, guest list, star chart) for Istio or Kubernetes
  concepts. Titles of pages and labs name the technical task ("Require mTLS
  With PeerAuthentication"), not a space story.
- **Show one real example before the rule.** Start with a concrete case the
  reader can run, then give the general rule.
- **Say which part does the work.** Readers often mix up the parts of a system
  that sit close together. Whenever something happens, say which component
  did it.
- **Never change code to fit the style.** Commands, configuration files, field
  names, resource names, log lines and command output stay exactly as they
  are. They were run and checked on a real system. Never make up command
  output. If you shorten it, say that you did.
- **Prose only.** The grade-level and sentence rules apply to explanations.
  They do not apply to code blocks, tables of field names or reference lists
  (those may stay short and dense).
- **Keep the page furniture the same.** Hands-on steps are part of the prose
  (see "Read like a book"), not boxes or headings of their own. A `> [!TIP]` box is
  only for a real tip: advice the reader can reuse beyond this one step (a
  habit, a shortcut, how to spot a problem, an exam habit). Everything else
  is a normal sentence: notes about the current step ("if the log line is
  old, run it again"), background facts, optional extra steps, and plain
  information. Never a command snippet, never two in a row, and most pages
  need zero or one tip. Each part ends with a
  `## Common pitfalls` `> [!WARNING]` block for that part only. Use a Mermaid
  diagram for a flow, an order or a state change, keep it under about 12
  boxes, and follow it with one sentence that says what it shows.
- **Labs come right after the part they practise.** Do not collect all
  graded labs at the end of a module. In `astrona.yaml`, put each lab (its
  `question.md` reading and the `lab` entry) right after the reading part it
  tests. If a part teaches a gradeable skill and no lab covers it, create a
  new lab. That part then ends with a `## Your mission: <lab title>` section:
  one sentence on what the reader can now do, one on what the mission asks,
  then pause the playground (`astrona stop <playground name>`), the
  `astrona run` and `astrona submit` commands, and finally
  `astrona destroy <lab name>` plus `astrona start <playground name>`.
- **Renew the playground before hands-on work.** Every reading part that
  runs commands has `<!-- astrona:playground:renew -->` exactly once, on its
  own line, right before the first hands-on step (the first "Save this as"
  or the first command block), so the playground timer is reset before the
  learner needs the playground. Not on landing pages (they carry
  `<!-- astrona:playground -->`), summary pages (they carry
  `<!-- astrona:playground:destroy -->`) or pages without commands.
- **Mermaid without HTML.** The platform renders Mermaid with HTML labels
  switched off, so `<br/>` and any other HTML tag break the drawing. Rules:
  - One line per box, no `<br/>`, no HTML. Keep the box to the thing's name
    (`"scout-v2"`, `"istiod"`, `"Service: scout"`).
  - Put the logic on the arrows: `E -->|"version: v2"| P2`,
    `I -->|"CDS"| C`, `A -->|"end-user: jason"| B`. Keep edge labels short.
  - Quote every label. Prefer `flowchart TB`; use `LR` only for a short chain.
  - Sequence diagrams: short participant aliases (`participant S as shuttle`)
    and short message text.
  - Anything longer (cluster names, full hostnames) goes in the sentence under
    the diagram.
- **Every course starts with an Introduction.** It lives in `sections/intro/`
  and is the first entry in `astrona.yaml` (`id: module-intro`, title
  "Introduction"). It has exactly these four pages, in this order:
  - `README.md`, `# Introduction`: what the introduction covers and its three
    pages, named in prose (no links), ending with the topic the course starts
    with.
  - `course-01-welcome.md`, `# Welcome To The Course`: who the course is for,
    the exam domain and what the reader can do at the end, the words the
    course uses, the example app, how the course is laid out and how to read
    a page.
  - `course-02-get-your-machine-ready.md`, `# Get Your Machine Ready`: the
    tools to install, the `astrona` commands used every day, and what to do
    when a start goes wrong.
  - `course-03-how-this-course-is-made.md`, `# How This Course Is Made`: how
    content is written and checked, the maintainers, how to report a mistake,
    and the license.
  The Introduction teaches no product content and has no playground, labs or
  summary. Its only links are the repository's contributors page, issues
  page and license.
- **No links to other course files.** A course page (every reading listed in
  `astrona.yaml`, the playground guide `docs/overview.md`, and a lab's
  `question.md` and `solution.md`) never links to or points the reader at
  another page or file of the repository: no links to parts, summaries,
  labs, `question.md`, other modules, sections or the Introduction, and no
  "see `practice.md`" or "open `config.yaml`". The platform shows the pages in
  the order of `astrona.yaml`, so a link only adds a second, often wrong,
  path. Name a thing in plain words when the reader needs it ("the task is on
  the next page"), and state a fact on the page itself instead of sending the
  reader somewhere else. Repository files for authors (the root `README.md`,
  a lab's or playground's `README.md`) may link.
- **No links to outside sources.** Course pages, labs and playground docs do
  not link to or point at outside websites (the one exception is the
  `resources` field of a lab entry in `astrona.yaml`) (official docs, GitHub, blogs,
  RFCs), and they have no "Reference" or "Official docs" lists. Everything the
  reader needs is explained on the page itself. Not affected: addresses the
  reader actually uses in a command or browser (`http://127.0.0.1:9080`,
  `curl https://httpbin.org`), and the Introduction's contributors and
  "report a mistake" links.
- **Configuration goes to a file first.** Whenever the reader should apply
  YAML (course parts, playground docs, labs), use three separate steps:
  1. "Save this as `virtualservice-scout.yaml`:" followed by a plain
     ` ```yaml ` block with only the YAML. No `cat > file <<'EOF'`, no
     `kubectl apply -f - <<EOF`, no shell around it.
  2. "Apply it:" followed by a ` ```sh ` block with only
     `kubectl apply -f virtualservice-scout.yaml`.
  3. "Then check the result:" followed by the check commands, if any.
  The file name says the kind and the object. If a value must come from the
  reader's cluster (an IP address), use a placeholder like `<PARTNER>` in the
  YAML and say how to get the value (`echo $PARTNER`); never put shell
  variables inside YAML. Apply an object the first time its YAML appears; do
  not show it once "to read" and paste it again later. Never tell the reader
  to apply something from the playground's `examples/` folder: they start the
  playground with `astrona run`, so that folder is not on their machine.
- **Helpers have readable names.** Shell helper functions and variables use
  names that say what they do (`check_route`, `count_versions`,
  `$SERVICE_URL`), never single letters.


## About this repo (ATS089 only)

Everything above is general and can be copied to other course repositories. This
section is only true for this one.

### What the student is trying to learn

- **The goal:** master the **Realm Administration & Identity Management**
  domain of the **Keycloak** training path (`ATP018`). It is 20% of the path.
  There is no official Keycloak certification exam; the path's domains and
  weights are Astrona's own, set in `ATP018/path.yaml`.
- **What the domain really tests:** administering a realm by hand and from the
  terminal, not remembering words. The student must *do* things (find why a
  user cannot sign in, give a group the roles its members need, read roles in
  a token, change an authentication flow, set a password policy, connect an
  LDAP directory, add an identity provider). Every explanation should lead to
  a command they can run, and every fix should be proved with a real token
  request that failed before and succeeds after, or with the setting read
  back from the Admin REST API when no terminal request can prove it.
- **The four topics:** the user lifecycle, roles and groups, authentication
  flows with multi-factor authentication (MFA) and passkeys, and user
  federation with identity brokering. The README table maps each section to
  its topic.
- **The sections:**

  | Section | Title | Topic |
  | --- | --- | --- |
  | 010 | Users And The User Lifecycle | Users |
  | 020 | Roles, Composite Roles And Groups | Roles and groups |
  | 030 | Authentication Flows, MFA And Passkeys | Authentication |
  | 040 | User Federation And Identity Brokering | Federation and brokering |

- **The version:** everything is written for **Keycloak 26.8.1**, image
  `quay.io/keycloak/keycloak:26.8.1`, on a single-node `kind` cluster. Do not
  teach fields, flags or output from other versions without saying so. Pin
  every image tag; never use `latest`.
- **The main sources:** the Server Administration Guide,
  <https://www.keycloak.org/docs/latest/server_admin/index.html>, and the
  Keycloak guides, <https://www.keycloak.org/guides>. Check every page against
  them.

### Status: built, not yet run

The first version of this repository was written from the Keycloak 26.8.1
documentation **without a live run**. No playground or lab has been started,
and no `astrona test` has passed yet. Until a maintainer runs them:

- Pages describe results in words. Do not add `text` output blocks until the
  output comes from a real run, and then paste it exactly.
- Treat every lab as unverified. Run `astrona validate` and `astrona test` on
  each one, one cluster at a time, before the course goes past `maturity:
  draft`.
- These facts were written from memory or from the documentation and need a
  live check first: the names of the subflows in a copy of the `browser` flow,
  the configuration key of the `Condition - user role` execution
  (`condUserRole`), the `error_description` texts of the token endpoint, the
  `osixia/openldap:1.5.0` image on arm64 machines, and the HTML id of an
  identity provider link on the login page (`social-partner`).
- Remove this subsection when every lab has passed `astrona test`.

### Terms, not metaphors

Explanations use Keycloak's, LDAP's and OpenID Connect's own words. Define
each one in plain technical language on first use in a file, for example:

| Term | First-use definition (example wording) |
| --- | --- |
| Realm | A space in Keycloak that holds its own users, clients, roles, groups and settings; realms do not see each other |
| User profile | The realm's list of user attributes, with the rules for who may see and edit each one and which ones are required |
| Required action | A task a user must finish at the next sign-in before Keycloak issues tokens, for example `UPDATE_PASSWORD` or `VERIFY_EMAIL` |
| Credential | Something a user proves who they are with: a password, an OTP device or a WebAuthn key |
| Temporary password | A password that works once and then forces the `UPDATE_PASSWORD` required action |
| Impersonation | An administrator signing in as another user, to see what that user sees |
| Realm role / client role | A role defined for the whole realm / a role defined by one client, usually the API that checks it |
| Composite role | A role that contains other roles; a user with it gets all of them |
| Default roles | The composite role `default-roles-<realm>` that every new user of the realm gets |
| Group | A set of users; roles mapped to a group apply to every member, and subgroups inherit them |
| Client scope | A named set of protocol mappers and role scopes that a client can request; the `roles` scope puts roles in tokens |
| `realm_access` / `resource_access` | The access token claims that list the user's realm roles / the user's client roles per client |
| Authentication flow | An ordered tree of executions that Keycloak runs when a user signs in |
| Execution | One step in a flow (an authenticator, a condition or a subflow) with a requirement: `REQUIRED`, `ALTERNATIVE`, `DISABLED` or `CONDITIONAL` |
| One-time password (OTP) | A short code from an app on the user's phone (TOTP: time-based; HOTP: counter-based) |
| WebAuthn / passkey | The W3C standard for signing in with a hardware or platform authenticator / a WebAuthn credential that replaces the password |
| Password policy | Rules a new password must pass, for example `length(12)` |
| User federation | Keycloak reading users from an outside store, such as an LDAP directory, instead of its own database |
| LDAP | Lightweight Directory Access Protocol: the protocol for reading and writing a directory of users and groups |
| User Storage SPI | The Java interface a user federation provider implements; the LDAP provider is one implementation |
| Edit mode | How the LDAP provider handles changes: `READ_ONLY`, `WRITABLE` or `UNSYNCED` |
| Mapper (LDAP / identity provider) | A rule that copies one attribute or group between the outside system and the Keycloak user |
| Identity brokering | Keycloak sending a user to another identity provider to sign in, then creating or linking a local user |
| First broker login flow | The flow Keycloak runs the first time a user arrives from an identity provider |

Do not invent friendly names for these (no "the key ring", "the bouncer",
"the guest list"). The product's names are what the student meets in the
console and the logs.

### The example workloads

Every module deploys the same small setup into its own namespace
(`users-demo`, `roles-demo`, `flows-demo`, `ldap-demo`, `broker-demo`;
capstones use `userscapstone-demo`, `rolescapstone-demo`,
`flowscapstone-demo` and `federationcapstone-demo`).

| Kubernetes name | Image | What it is |
| --- | --- | --- |
| `keycloak` (Deployment and Service) | `quay.io/keycloak/keycloak:26.8.1` | One Keycloak pod in development mode. Service port `8080` (`http`) and `9000` (`management`) |
| `keycloak-admin` (Secret) | | Bootstrap administrator: user `admin`, password `admin`. Lab-only credentials; say so when a page uses them |
| `openldap` (Deployment and Service) | `osixia/openldap:1.5.0` | OpenLDAP on port `389`, base DN `dc=example,dc=org`, administrator `cn=admin,dc=example,dc=org` with password `ldap-admin-password`; only in section 040 module 1 and the section 040 capstone |
| `openldap-seed` (ConfigMap) | | LDIF with `ou=people` (`ldap-ana`, `ldap-ben`, password `ldap-password`) and `ou=groups` (`warehouse`, member `ldap-ana`) |
| `tester` | `nicolaka/netshoot:v0.13` | Client pod with `curl` and `jq`. Every test request is sent from here with `kubectl exec deploy/tester -- ...` |

Inside Keycloak, every module uses the same names:

| Keycloak name | What it is |
| --- | --- |
| realm `inventory` | The application realm |
| user `alice` | Password `alice-password`, complete profile; the user every module starts from |
| users `bob`, `carol`, `dave`, `erin`, `frank`, `mallory` | Extra users in section 010 and the role labs, each with a password of the form `<name>-password` unless a page says otherwise |
| client `inventory-cli` | Public client with **Direct access grants** on, used to request tokens with the password grant |
| client `inventory-api` | The API; it defines the client roles `stock-read` and `stock-write` |
| client `inventory-web` | Confidential client with the standard flow, used where a browser sign-in page is needed |
| realm role `warehouse-clerk`, `stock-admin` | The roles the role and flow modules work with |
| group `warehouse`, `auditors` | The groups the user and role modules work with |
| realm `partner`, user `pat`, client `inventory-broker` | The second realm that acts as an OpenID Connect identity provider for `inventory` in section 040 module 2 |

The password grant (`grant_type=password`, "Direct access grants" in the
console) is used **only** so a grader and the reader can get a token for a
user from a terminal. Say every time it is used that OAuth 2.1 drops it and a
real application uses the authorization code flow.

### Environment facts the text must respect

- **Keycloak runs as plain Kubernetes manifests** in development mode
  (`start-dev`). Every playground and lab applies `manifests/lab-start.yaml`
  and waits for `deployment/keycloak`.
- **The administration helper.** Pages and scripts call `kcadm.sh` inside the
  Keycloak pod, with the configuration file in `/tmp`:

  ```sh
  kcadm() {
    kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
      /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
  }
  kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
  ```

  The session from `config credentials` expires; run it again when `kcadm`
  answers `401`. A pod restart deletes `/tmp/kcadm.config`.
- **JSON work happens in the `tester` pod.** The reader's machine may not
  have `jq`, so scripts that change a JSON document (the user profile, a flow
  execution) pipe it through `kubectl exec -i deploy/tester -- jq ...`.
- **The `tester` pod reaches Keycloak at `http://keycloak:8080`**, so the
  issuer in a token is `http://keycloak:8080/realms/<realm>`. A browser
  reaches Keycloak through
  `kubectl -n <namespace> port-forward svc/keycloak 8080:8080`, and then the
  issuer is `http://localhost:8080/realms/<realm>`. Never mix the two in one
  example.
- **Identity brokering uses `http://localhost:8080` for the `partner` realm.**
  The browser reaches it through the port-forward, and the Keycloak pod
  reaches its own `localhost:8080` for the back-channel token request, so one
  issuer, `http://localhost:8080/realms/partner`, works for both. Explain this
  in one sentence where a page needs it.
- **The user profile is on by default.** First name, last name and email are
  required for the role `user` only: an administrator can create a user with
  just a username (the Server Administration Guide: "Username is the only
  required field"), but that user meets `VERIFY_PROFILE` and cannot finish
  signing in until the profile is complete. The profile is read and written at
  `users/profile` in the Admin REST API.
- **Passkeys need a browser and an authenticator.** No grader can register a
  WebAuthn credential. Labs in section 030 grade the configuration (policy,
  required action, flow) and say so plainly.
- **Many environments start broken on purpose.** A lab seeds the fault after
  Keycloak is up (a disabled user, a missing role mapping, a disabled
  execution, a wrong LDAP setting). The fault is the material. Never "fix" it
  in the bootstrap.
- **Keycloak is slow to start.** Allow up to five minutes for the first
  rollout. Probes use `/health/started`, `/health/ready` and `/health/live`
  on port `9000`.
- **The proof is a token request from `tester`.** Decode tokens with this
  `jq` filter, which also adds the Base64 padding a JWT leaves out:

  ```sh
  jq -R 'split(".")[1] | gsub("-";"+") | gsub("_";"/") | . + ("=" * ((4 - length % 4) % 4)) | @base64d | fromjson'
  ```

### Where things are in this repo

| What | Where |
| --- | --- |
| Course outline the platform reads: every reading page and lab, in order. Never list `solution.md` here | `astrona.yaml` |
| Overview, sections and modules tables, how to run things | `README.md` |
| Introduction (see "Every course starts with an Introduction") | `sections/intro/` |
| Section overview and its modules | `sections/section-0N0/README.md` |
| Module reading: landing page, deep-dive parts, closing page | `sections/section-0N0/module-0M/course.md`, `course-0N-*.md` |
| Graded lab: task, walkthrough, setup, grader | `.../labs/lab-01/` (`question.md`, `solution.md`, `prerequisites.md`, `bootstrap/`, `manifests/`, `solution/`, `testing/`, `validation/`) |
| Ungraded sandbox for a module | `.../playground/` (`config.yaml`, `bootstrap/prepare.sh`, `manifests/`, `docs/overview.md`, which is the only learner page) |
| One graded integration lab per section | `sections/section-0N0/capstone/labs/lab-01/` |

A lab folder holds:

| Path | Purpose |
| --- | --- |
| `config.yaml` | Lab definition; `metadata.docs` points at `question.md` and `solution.md` |
| `README.md` | Short intro for authors with `estimated_duration` front matter and the run, submit and destroy commands |
| `prerequisites.md` | What the learner needs before starting |
| `question.md` | The task. Starts with `# Question` and `Solve this question on: \`terminal\`` |
| `solution.md` | Step-by-step walkthrough |
| `bootstrap/01-deploy-keycloak.sh`, `02-seed-state.sh` | Keycloak (and OpenLDAP) deployment and the broken starting state |
| `manifests/` | `lab-start.yaml` (workloads) and any extra objects |
| `solution/apply.sh` | Reference end state, applied only by `astrona test` |
| `testing/wait-for-keycloak.sh` | Waits until Keycloak answers before the reference solution runs |
| `validation/validate-*.sh` | Behavioural grading, one script per check |

### Lab metadata in `astrona.yaml`

`astrona.yaml` has a `training:` block (id `ATS089`, domain
`Realm Administration & Identity Management`, weight `20`) and one entry per
section under `modules:` (`module-010` to `module-040`). Each section's
`content` lists, in order: the section `README.md`, then for each module its
landing page, its parts, and right after the part a lab tests, a `Question`
reading (`labs/lab-01/question.md`) followed by the `type: lab` entry; the
module's closing page comes last. The section capstone closes the section.
Playgrounds are not listed: the landing page's `<!-- astrona:playground -->`
marker shows them.

Every `type: lab` entry carries the same fields, in the same order, as in
ATS016: `title`, `path`, `difficulty`, `estimated_duration`, `topic`,
`task_kind`, `tags`, `learning_goals`, `resources`.

- `difficulty`: `beginner`, `intermediate` or `advanced`.
- `estimated_duration`: realistic time to solve it, for example `15m`, `30m`.
- `topic`: exactly one of `users`, `roles`, `authentication`, `mfa`,
  `federation`, `brokering`.
- `task_kind`: exactly one of `build`, `troubleshooting` or `migration`.
- `tags`: 4 to 8 ids, only from the tag list below. Add a new tag to the list
  first if nothing fits.
- `learning_goals`: 2 or 3 plain sentences, each starting with a verb.
- `resources`: 1 to 4 pages on `keycloak.org`, each with a `name` and a `url`
  that loads. This is the **only** place outside links are allowed.

**Tag list** (lower case, hyphens, never synonyms):

- Users: `users`, `user-profile`, `required-actions`, `credentials`,
  `temporary-password`, `user-sessions`, `impersonation`, `kcadm`
- Roles and groups: `realm-roles`, `client-roles`, `composite-roles`,
  `default-roles`, `groups`, `role-mappings`, `client-scopes`,
  `token-claims`
- Authentication: `authentication-flows`, `executions`, `conditional-otp`,
  `otp-policy`, `password-policy`, `webauthn`, `passkeys`,
  `password-grant`
- Federation and brokering: `ldap`, `user-federation`, `user-storage-spi`,
  `edit-mode`, `ldap-mappers`, `ldap-sync`, `identity-brokering`,
  `oidc-identity-provider`, `idp-mappers`, `first-broker-login`

### Running things

```bash
# Playground (ungraded)
astrona run --git ssh://git@github.com/astrona-io/ATS089.git -c sections/section-010/module-01/playground
astrona destroy ats-089-playground-010-01   # takes metadata.name from config.yaml, not the path

# Lab or capstone (graded against the live cluster)
astrona run --git ssh://git@github.com/astrona-io/ATS089.git -c sections/section-010/module-01/labs/lab-01
astrona submit -c sections/section-010/module-01/labs/lab-01
astrona destroy ats-089-lab-010-01

# Authors: run a local, uncommitted copy, and prove a lab passes with its reference solution
astrona run -c sections/section-010/module-01/playground
astrona test -c sections/section-010/module-01/labs/lab-01
```

Names: a playground is `ats-089-playground-<section>-<module>`, a module lab
is `ats-089-lab-<section>-<module>` and a capstone is
`ats-089-capstone-<section>`; keep those names. Lab bootstrap scripts do not
pin a kube context: astrona sets `KUBECONFIG` for the lab. Every lab must pass
`astrona validate` and `astrona test`.

Graders check **behaviour**, not just that an object exists: request a real
token from `tester` and check its claims, or try the thing a policy must
refuse. Graders also reject the plausible but wrong fix (deleting and
recreating a user instead of fixing it, mapping a role straight to a user
instead of to the group, turning off the user profile, setting the LDAP edit
mode to `WRITABLE` to make a sign-in work, disabling the flow instead of
fixing it). A lab's `question.md` and `solution.md` must match what its
`validation/` scripts actually check.

Test clusters on the maintainer's machine: one at a time. Keycloak needs about
1 GiB of memory per cluster; section 040 adds OpenLDAP.

### Where to find trusted sources

Check facts here before writing them down. Prefer these over memory.

- **Server Administration Guide** (one long page; the anchors below are its
  sections): [managing users](https://www.keycloak.org/docs/latest/server_admin/index.html#assembly-managing-users_server_administration_guide),
  [user profile](https://www.keycloak.org/docs/latest/server_admin/index.html#user-profile),
  [roles and groups](https://www.keycloak.org/docs/latest/server_admin/index.html#assigning-permissions-using-roles-and-groups),
  [authentication flows](https://www.keycloak.org/docs/latest/server_admin/index.html#_authentication-flows),
  [OTP policies](https://www.keycloak.org/docs/latest/server_admin/index.html#one-time-password-otp-policies),
  [WebAuthn](https://www.keycloak.org/docs/latest/server_admin/index.html#webauthn_server_administration_guide),
  [password policies](https://www.keycloak.org/docs/latest/server_admin/index.html#_password-policies),
  [user federation and LDAP](https://www.keycloak.org/docs/latest/server_admin/index.html#_user-storage-federation),
  [identity brokering](https://www.keycloak.org/docs/latest/server_admin/index.html#_identity_broker),
  [Admin CLI](https://www.keycloak.org/docs/latest/server_admin/index.html#admin-cli)
- **Server Developer Guide:** [User Storage SPI](https://www.keycloak.org/docs/latest/server_development/index.html#_user-storage-spi)
- **Container and configuration:** [containers](https://www.keycloak.org/server/containers),
  [configuration](https://www.keycloak.org/server/configuration)

### Skills to use here

The `astrona-course-*` skills do most authoring jobs in this repository:
planning (`domain-plan`), creating the tree (`domain-scaffold`), building
modules (`domain-build`), deep-dive parts (`deep-dive`), labs and playgrounds
(`lab`), lab docs (`lab-docs`), challenges (`create-challenge`), quizzes
(`generate-assessment`) and fact-checking (`review-accuracy`).
