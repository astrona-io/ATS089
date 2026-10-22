# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Users

## Scenario

Three people in the realm `inventory` report that they cannot sign in to the command-line tool `inventory-cli`. Each of them is sure they type the right password, and each is right:

| User | Password |
| --- | --- |
| `bob` | `bob-password` |
| `carol` | `carol-password` |
| `dave` | `dave-password` |

This request from the `tester` pod should return an access token for each of them, but it does not. Replace `bob` and `bob-password` with each user in turn:

```sh
kubectl -n users-demo exec deploy/tester -- \
  curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=password \
    -d client_id=inventory-cli \
    -d username=bob \
    -d password=bob-password
```

The password grant is used here only so you can test from a terminal. A real application would use the authorization code flow.

## Your task

In the realm `inventory` and the namespace `users-demo`:

1. Find why each of the three users gets no token. Use the `error_description` of each response and the user's settings.
2. Fix each user so the request above returns an access token for all three, with the passwords in the table.

## Constraints

- **Fix the users that exist.** Do not delete or recreate `bob`, `carol` or `dave`. The grader compares their IDs with the ones the lab started with.
- Do not change the realm's user profile. A last name stays required for users.
- Do not disable any required action for the realm, including `VERIFY_PROFILE`.
- Keep each user's password as given in the table.
- Do not change the ConfigMap `lab-baseline`.

## Done when

- `bob`, `carol` and `dave` each get an access token with the request above.
- All three have the same IDs as at the start.
- The user profile still requires a last name, and `VERIFY_PROFILE` is still enabled.
