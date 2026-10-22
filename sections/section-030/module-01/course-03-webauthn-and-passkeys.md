# WebAuthn And Passkeys

A one-time code is better than a password alone, but a user can still type it into a fake site. WebAuthn removes that risk: the credential is a key pair kept by the user's device, and the device signs only for the site that registered it. A passkey goes one step further and replaces the password. This part explains both, and sets up the realm settings a passkey needs.

## What WebAuthn and a passkey are

**WebAuthn** (Web Authentication) is a W3C standard for signing in with an authenticator: a security key, or a platform authenticator built into a phone or a laptop. At registration, the authenticator creates a key pair for one site and gives the site the public key. At sign-in, the site sends a challenge, and the authenticator signs it with the private key, which never leaves the device. A **passkey** is a WebAuthn credential that can be used instead of a password, often synced between a user's devices.

Keycloak supports WebAuthn in two roles, each with its own policy:

| Use | Realm policy | Required action | Authenticator in a flow |
| --- | --- | --- | --- |
| Second factor after the password | WebAuthn Policy | `webauthn-register` | WebAuthn Authenticator |
| Passwordless sign-in (passkey) | WebAuthn Passwordless Policy | `webauthn-register-passwordless` | WebAuthn Passwordless Authenticator |

## Reading the passwordless policy

Paste the helper for this part. `kcadm` runs Keycloak's administration command-line tool inside the Keycloak pod:

<!-- astrona:playground:renew -->

```sh
NAMESPACE=flows-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
```

The policy is a group of realm fields that all start with `webAuthnPolicyPasswordless`. Print them:

```sh
kcadm get realms/inventory | jq 'with_entries(select(.key | startswith("webAuthnPolicyPasswordless")))'
```

The fields that matter most:

| Field | What it decides |
| --- | --- |
| `webAuthnPolicyPasswordlessRpEntityName` | The site name the authenticator shows the user |
| `webAuthnPolicyPasswordlessRpId` | The site the credential belongs to; empty means the host name of the request |
| `webAuthnPolicyPasswordlessUserVerificationRequirement` | Whether the device must verify the user (PIN, fingerprint): `required`, `preferred` or `discouraged` |
| `webAuthnPolicyPasswordlessRequireResidentKey` | Whether the credential must be stored on the device, which a passkey needs |
| `webAuthnPolicyPasswordlessSignatureAlgorithms` | The signature algorithms Keycloak accepts |

For a passkey, user verification must be `required`: the passkey replaces the password, so the device must prove that its owner is present. Set it and a readable site name:

```sh
kcadm update realms/inventory \
  -s webAuthnPolicyPasswordlessUserVerificationRequirement=required \
  -s 'webAuthnPolicyPasswordlessRpEntityName=Inventory'
```

## The required action that registers a passkey

A user registers a passkey through the required action `webauthn-register-passwordless`. It must be enabled in the realm before a user, or an administrator on the user's behalf, can use it. Read its state and enable it:

```sh
kcadm get authentication/required-actions/webauthn-register-passwordless -r inventory --fields alias,enabled
kcadm update authentication/required-actions/webauthn-register-passwordless -r inventory -s enabled=true
```

To ask `bob` to register a passkey at his next sign-in, add the action to him:

```sh
BOB_ID="$(kcadm get users -r inventory -q username=bob -q exact=true --fields id --format csv --noquotes | tr -d '\r')"
kcadm update "users/$BOB_ID" -r inventory -s 'requiredActions=["webauthn-register-passwordless"]'
```

## What a grader can and cannot check

Registering a passkey needs a browser and a real authenticator, so no script can do it. If you want to try it, run `kubectl -n flows-demo port-forward svc/keycloak 8080:8080` and sign in as `bob` at `http://localhost:8080/realms/inventory/account/`. Browsers allow WebAuthn on `http://localhost` without TLS, so your laptop's platform authenticator or a security key can register a passkey there. After the password, Keycloak asks `bob` to register one.

A passwordless sign-in also needs a flow that offers the WebAuthn Passwordless Authenticator, usually as an alternative to the username and password form, in a copy of the browser flow. That is built the same way as the OTP change: copy, add the execution, set its requirement, bind. Because no script can sign in with a passkey, the graded work in this module checks the configuration: the policy fields, the required actions and the flow, read back from the Admin REST API.

You now know what makes a passkey safer than a code, which realm policy and required action it needs, and why its setup is checked by reading the configuration. Together with the password policy and conditional OTP, that covers the main ways to strengthen a sign-in.

## Common pitfalls

> [!WARNING]
> - **Mixing up the two WebAuthn policies.** The WebAuthn Policy is for a second factor; the WebAuthn Passwordless Policy is for passkeys. Change the one your flow uses.
> - **Leaving user verification at `discouraged` for passkeys.** A passkey then proves only that someone holds the device.
> - **Setting `RpId` to a host the browser does not use.** The credential is tied to that site, and sign-ins from another host fail.
> - **Adding the required action while it is disabled.** The user is never asked. Enable it in the realm first.
