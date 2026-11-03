# Searching Users And Bulk Work With kcadm

A realm with a handful of users is easy to manage by hand. A realm with thousands of users is not. You need to find one account fast, count accounts, page through a long list and load many users at once. This part shows the Admin REST API calls behind those jobs, so that a script can do in one command what takes many clicks in the Admin Console.

## Finding and counting users

The Admin REST API endpoint `users` accepts query parameters that narrow the list. `kcadm.sh` sends each `-q name=value` as one query parameter. The parameters `username`, `email`, `firstName` and `lastName` match part of the field. The parameter `search` looks in the username, the email address, the first name and the last name at once. The parameter `exact=true` switches the field parameters from partial to exact matching.

Paste the helper and sign in as the lab-only administrator:

<!-- astrona:playground:renew -->

```sh
NAMESPACE=users-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
```

Search for every user whose data contains `example`, and show only the username. Then count all users in the realm. The `users/count` endpoint returns a single number:

```sh
kcadm get users -r inventory -q search=example --fields username
kcadm get users/count -r inventory
```

The first command lists `alice` and `bob`, because both have an email address at `example.com`. The second command prints the number of users in the realm.

## Paging through a long list

A list call returns at most 100 users by default. The parameter `first` sets the position to start at, counted from zero, and `max` sets how many users to return. Use both to read a long list in pages. The parameter `briefRepresentation=true` asks for a shorter record for each user, which is faster on large realms:

```sh
kcadm get users -r inventory -q first=0 -q max=1 --fields username
kcadm get users -r inventory -q first=1 -q max=1 --fields username
```

Each command returns one user. The order is stable, so the second page continues where the first one stopped.

## Searching by attribute

The parameter `q` searches custom attributes. Its value is `name:value`, and several pairs are separated by spaces. It finds users whose stored attribute matches. For example, `-q q=department:logistics` returns users with the attribute `department` set to `logistics`. The attribute must exist on the user, so add it to the realm's user profile first and then set it on the user. Searching for an attribute that no user has returns an empty list, not an error.

## Loading many users at once

Creating users one by one takes one command each. The `partialImport` endpoint loads many users in one call. The body names a policy in `ifResourceExists`: `FAIL` stops with an error, `SKIP` leaves existing users untouched and `OVERWRITE` replaces them.

Save this as `users-import.json`:

```json
{
  "ifResourceExists": "SKIP",
  "users": [
    {
      "username": "import-one",
      "enabled": true,
      "email": "import-one@example.com",
      "firstName": "Import",
      "lastName": "One",
      "credentials": [
        { "type": "password", "value": "import-one-password", "temporary": true }
      ]
    },
    {
      "username": "import-two",
      "enabled": true,
      "email": "import-two@example.com",
      "firstName": "Import",
      "lastName": "Two"
    }
  ]
}
```

Send the file to the Keycloak pod through standard input, then count the users again:

```sh
kcadm create partialImport -r inventory -f - < users-import.json
kcadm get users/count -r inventory
```

The response reports how many users Keycloak added, skipped or overwrote. The count grows by two. Run the import a second time: with `SKIP`, nothing is added and both users are reported as skipped. The first user gets a temporary password, so Keycloak adds the required action `UPDATE_PASSWORD` for that user.

## Exporting a list

To hand a list to another team, ask `kcadm.sh` for CSV output. `--format csv` prints one row per user with the fields you choose, and `--noquotes` removes the quotation marks:

```sh
kcadm get users -r inventory --fields username,email --format csv --noquotes
```

You can now find, count, page, load and list users from a script. A script that depends on these calls must still handle the 100-user default page size. The next step is to decide who may do such bulk work at all, which is a question of roles.

## Common pitfalls

> [!WARNING]
> - **Reading only the first page.** A list call without `max` returns at most 100 users. Page with `first` and `max`, or use `users/count` to know the total.
> - **Partial matches in scripts.** `username=al` matches every name that contains `al`. Add `exact=true` when you need one user.
> - **Choosing `OVERWRITE` by habit.** It replaces existing users, including their attributes. Use `SKIP` unless replacing is the goal.
> - **Putting a real password in an import file.** The file holds the password in clear text. Use `temporary: true` so the user must change it.
