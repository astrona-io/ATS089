# Configure Login, Email And Display Settings Of A Realm

A realm decides how its sign-in page behaves before it decides anything about a single user. Can a visitor register? Can a user reset a forgotten password? Does the realm send an email to check an address? Which language and which look does the page use? Each answer is a setting of the realm, and a wrong value can lock users out without any error message in the logs.

A **realm setting** is a property of the realm itself, stored on the realm representation, the JSON document the Admin REST API returns for `realms/<name>`. This module teaches the settings that shape the sign-in experience and shows how to read and change each one from the terminal. Keep one sentence in mind: **a setting that needs another service, such as email verification, works only when that service is configured too.**

The module has four parts. **Login Options Of A Realm** covers registration, forgotten passwords, remember me and the email and username rules. **Email Settings And Email Verification** covers the SMTP server a realm uses and what happens when verification has no server behind it. **Localization And Themes** covers languages and the four themes, and a graded lab follows it. **Reading And Changing The Realm Representation** covers how all of these settings are stored and how to change them safely.

## Learning objectives

After this module you can:

- Turn user registration, forgotten password, remember me, email as username and duplicate emails on and off, and explain what each does.
- Configure the SMTP server of a realm and explain why `verifyEmail` needs it.
- Enable several languages and choose the default language.
- Select the login, account, admin and email themes of a realm.
- Read a realm representation, change one field without changing the others, and prove the change.

## Before you start

You need Kubernetes basics (`kubectl get`, `kubectl exec`) and the idea that a realm holds users and clients. The earlier parts of this course used `kcadm.sh`, Keycloak's administration command-line tool, which sends calls to the Admin REST API.

Your playground is a single-node `kind` cluster with **Keycloak 26.8.1** in development mode. The namespace **`realm-settings-demo`** runs these workloads:

| Workload | What it is |
| --- | --- |
| `keycloak` | One Keycloak pod behind the Service `keycloak` on port `8080` |
| `tester` | A client pod with `curl` and `jq` |

Keycloak holds the realm `inventory` with the user `alice` (password `alice-password`) and the client `inventory-web`. The administrator of the `master` realm is `admin` with the password `admin`. These are lab-only credentials.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
