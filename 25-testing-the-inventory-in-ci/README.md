# 25: testing the inventory in CI

Example for [item 25](https://til.housni.eu/ansible/inventory-testing-in-ci-json-schema.html).

The app/db, prod/staging inventory of the series, tested the way a CI job
would: without connecting to any host and without the vault password.

| Path | What it shows |
|---|---|
| `inventory/` | the inventory under test: `app` and `db` groups, `prod` and `staging` groups, PostgreSQL variables, and a password kept as an alias to a `vault_` variable encrypted with `ansible-vault encrypt_string` |
| `schema/inventory.schema.json` | the JSON Schema: variables each group's hosts need, their types, allowed values (`enum`), patterns, and no secret in clear |
| `policy.yml` | the rules a schema can't express, as `assert` tasks: no host only in `ungrouped`, every host in exactly one of `prod` and `staging` |
| `check.sh` | the test: `ansible-inventory --list`, reshaped with `jq` to `{group: {host: variables}}`, validated with `check-jsonschema`, then `policy.yml` |
| `ci/inventory.yml` | a GitHub Actions workflow running `check.sh`, to copy into `.github/workflows/` of an inventory repository (not active here) |
| `broken/<case>/` | one failure per case, as the files that differ from `inventory/` |
| `pitfalls/whole-file-vault/` | a `vault.yml` encrypted as a whole: `ansible-inventory` then fails without the password |

`run.sh` prints the document the schema validates, runs `check.sh` on
`inventory/`, then on a copy of `inventory/` with each `broken/<case>/`
laid over it, and prints each check's messages and exit code.

The encrypted values use the test-only vault password of
[example 10](../10-secrets-in-the-inventory/vault-pass/test.txt); no check
needs it.

```sh
./run.sh
```

It needs `check-jsonschema` (in `requirements.txt`) and `jq`. Compare with
[`expected.txt`](expected.txt).
