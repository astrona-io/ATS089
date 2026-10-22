# Control How Users Sign In With Flows, OTP And Passkeys — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-089-playground-030-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

A single sandbox environment that spins up, deploys Keycloak 26.8.1 in the
namespace `flows-demo`, creates the realm `inventory` with the users `alice` and `bob` and the realm role `stock-admin`, and stays running so you can explore the module's
topic. Nothing to submit.

> **Not yet run.** This playground was written from the Keycloak 26.8.1
> documentation and has not been started yet.

## Run it

```sh
astrona run -c .
astrona destroy ats-089-playground-030-01
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-089-playground-030-01`), not
the config path. `astrona submit` and `astrona test` do not apply — there is no
grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime + bootstrap only) |
| `bootstrap/prepare.sh` | Deploys Keycloak and creates the module's starting objects |
| `manifests/lab-start.yaml` | Namespace, Keycloak, Service and tester pod |
| `docs/overview.md` | What the environment contains and ideas to try |
