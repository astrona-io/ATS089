# Overview: Sign Users In Through Another Identity Provider (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, deploys Keycloak, creates two realms and the client one realm needs to broker the other, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- Namespace **`broker-demo`** with these workloads:

  | Workload | What it is |
  | --- | --- |
  | `keycloak` | One Keycloak 26.8.1 pod in development mode, behind the Service `keycloak` on port `8080` |
  | `tester` | Client pod with `curl` and `jq` |

- In Keycloak:

  | Keycloak object | What it is |
  | --- | --- |
  | realm `inventory` | The broker: user `alice`, clients `inventory-cli` and `inventory-web` (secret `inventory-web-secret`), realm role `partner-user`, and no identity provider yet |
  | realm `partner` | The identity provider: user `pat` (password `pat-password`) |
  | client `inventory-broker` in `partner` | Confidential client, secret `inventory-broker-secret`, redirect URI `http://localhost:8080/realms/inventory/broker/partner/endpoint` |

- The administrator of the `master` realm is `admin` with the password `admin`. All of these are lab-only credentials.

## Helpers

Paste these once in each new terminal. `kcadm` runs Keycloak's administration command-line tool inside the Keycloak pod.

```sh
NAMESPACE=broker-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
```

For a brokered sign-in in a browser, run `kubectl -n broker-demo port-forward svc/keycloak 8080:8080` in a second terminal and open `http://localhost:8080/realms/inventory/account/` in a private window. Every endpoint of the identity provider uses `http://localhost:8080`, which your browser reaches through the port-forward and the Keycloak pod reaches as its own address.

## Practice tasks

- Add the identity provider `partner` and sign in as `pat` through it. Then read `pat`'s federated identity in `inventory`.
- Change the provider's sync mode to `FORCE`, change `pat`'s last name in `partner`, sign in again, and compare.
- Add an **Attribute Importer** mapper that copies the claim `email` into a user attribute.
- Create a local user `pat` in `inventory` with the email `pat@example.com` before the first brokered sign-in, and watch the first broker login flow offer to link the accounts.
- Set `hideOnLogin` on the provider and use `kc_idp_hint=partner` in the sign-in URL to go straight to `partner`.
