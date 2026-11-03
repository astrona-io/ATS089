# Summary

An organization groups the users of one realm under a name, an alias, domains and attributes. It is a grouping inside the realm, not a separate realm.

## What you learned

The realm field `organizationsEnabled` turns the feature on. `kcadm create organizations` creates an organization with a unique name and a unique alias. The alias cannot be changed. Calls on one organization use its id.

Domains identify an organization from an email address. An exact domain matches one name, a wildcard such as `*.acme.example` matches the base domain and its subdomains, and the most specific match wins. A domain belongs to one organization in a realm. Attributes hold extra facts, and setting them replaces the whole map.

A member is managed or unmanaged. A managed account is controlled by the organization and is removed with it. An unmanaged account belongs to the realm and stays when it leaves the organization. Members are added with the user id as a JSON string in the body.

The built-in optional scope `organization` writes the `organization` claim. The forms are `organization`, `organization:<alias>` and `organization:*`, and they cannot be mixed. The claim maps each alias to an object that can hold the id and the attributes.

- Turn the feature on per realm.
- Use ids in paths and aliases in scopes.
- Request the scope, or the claim is missing.

<!-- astrona:playground:destroy -->
