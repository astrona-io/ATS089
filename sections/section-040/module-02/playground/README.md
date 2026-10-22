# Sign Users In Through Another Identity Provider — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-089-playground-040-02
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

A single sandbox environment that spins up, deploys Keycloak 26.8.1 in the
namespace `broker-demo`, creates the realms `inventory` and `partner`, with the client `inventory-broker` in `partner`, and stays running so you can explore the module's
topic. Nothing to submit.

> **Not yet run.** This playground was written from the Keycloak 26.8.1
> documentation and has not been started yet.

## Run it

```sh
astrona run -c .
astrona destroy ats-089-playground-040-02
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-089-playground-040-02`), not
the config path. `astrona submit` and `astrona test` do not apply — there is no
grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime + bootstrap only) |
| `bootstrap/prepare.sh` | Deploys Keycloak and creates the module's starting objects |
| `manifests/lab-start.yaml` | Namespace, Keycloak, Service and tester pod |
| `docs/overview.md` | What the environment contains and ideas to try |
