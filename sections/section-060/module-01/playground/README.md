# Group Users Into Organizations — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-089-playground-060-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

A single sandbox environment that spins up and deploys Keycloak 26.8.1 in the
namespace `orgs-demo` and stays running so you can explore the module's topic.
Nothing to submit.

> **Not yet run.** This playground was written from the Keycloak 26.8.1
> documentation and has not been started yet.

## Run it

```sh
astrona run -c .
astrona destroy ats-089-playground-060-01
```

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime + bootstrap only) |
| `bootstrap/prepare.sh` | Deploys Keycloak and creates the starting state |
| `manifests/lab-start.yaml` | Starting workloads |
| `docs/overview.md` | The learner guide |
