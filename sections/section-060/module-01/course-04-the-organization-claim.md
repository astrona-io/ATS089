# The Organization Claim

An application that receives a token needs to know which organization the user acts for. Keycloak puts that in a token claim called `organization`. This part shows how a client asks for it, what the claim looks like and how to read it from the terminal.

## The organization scope

The `organization` scope is a built-in optional client scope of the realm. A new client gets it as an optional scope, so a client must ask for it in the `scope` parameter. It carries the mapper `Organization Membership`, which writes the claim. There are three forms of the request. `organization` maps a single organization when the user belongs to exactly one; if the user belongs to several, the user is asked to choose during the browser sign-in. `organization:<alias>` maps one named organization, and several can be requested together, for example `organization:acme organization:globex`. If an alias does not exist or the user is not a member, the request is rejected. `organization:*` maps every organization the user belongs to. Do not mix the forms in one request.

## What the claim contains

The claim is a map from the alias to a small object. By default the object is empty. The mapper can be edited to add the organization id and the organization attributes.

Paste the helper. Make sure `alice` is a member of `acme`, then request a token with the scope for that alias and decode its payload in the `tester` pod:

<!-- astrona:playground:renew -->

```sh
NAMESPACE=orgs-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
kubectl -n "$NAMESPACE" exec deploy/tester -- curl -s \
  http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
  -d grant_type=password -d client_id=inventory-cli -d username=alice -d password=alice-password \
  -d 'scope=openid organization:acme' \
  | kubectl -n "$NAMESPACE" exec -i deploy/tester -- jq -r '.access_token' \
  | kubectl -n "$NAMESPACE" exec -i deploy/tester -- jq -R 'split(".")[1] | gsub("-";"+") | gsub("_";"/") | . + ("=" * ((4 - length % 4) % 4)) | @base64d | fromjson | .organization'
```

The output is an object with the key `acme`. If `alice` is not a member, the token request is rejected, which is the check you want when an application must serve only members.

## Adding the id and the attributes

Open the client scope `organization` and its mapper to enable the options **Add organization id** and **Add organization attributes**. With them on, the object for `acme` holds the `id` and the attributes as lists. Keep attributes out of the claim when they are private to the administrators.

## Using the claim

An application should read the alias from the claim and check it before it serves data. A resource server that receives an access token can compare the alias with the tenant in the request. Never trust a tenant name sent by the client when the token says otherwise.

You now have the full path: enable organizations, create them, add members and read the membership in tokens. The summary collects the points.

## Common pitfalls

> [!WARNING]
> - **Not requesting the scope.** The claim is missing unless the client asks for `organization` in the `scope` parameter.
> - **Mixing scope forms.** `organization` with `organization:acme` is an error.
> - **Requesting an organization the user is not in.** Keycloak rejects the request.
> - **Putting private attributes in the claim.** Every holder of the token can read them.
