# 10: secrets in the inventory

Example for [item 10](https://til.housni.eu/ansible/inventory-secrets-vault-yml-aliases.html).

> **The vault passwords in `vault-pass/` are committed on purpose.** They are
> test values, named `…-TEST-ONLY-not-a-secret`, that encrypt dummy data so
> the example runs anywhere, CI included. Never commit a real vault password:
> keep it in a password manager, a CI secret or a vault client script.

| Path | What it shows |
|---|---|
| `alias/` | `group_vars/postgresql/vars.yml` in plaintext, with `postgresql_password: "{{ vault_postgresql_password }}"`, next to an encrypted `vault.yml` |
| `no-alias/` | `postgresql_password` defined only inside the encrypted file |
| `inline/` | the same secret as an inline `!vault` value from `ansible-vault encrypt_string`, in a plaintext `vars.yml` |
| `vault-ids/` | prod and staging secrets encrypted with different vault IDs |
| `use.yml` | uses the password once carelessly and once with `no_log: true` |

`run.sh` shows what each layout reveals: to `grep`, to
`ansible-inventory --host` with and without the vault password, to a
playbook's output, and to `diff` when the secret changes or is rekeyed; then
what a missing vault ID password does. It prints whether the secret appears
in clear, never the ciphertext, which changes at every encryption.

```sh
./run.sh
```

It needs `jq`. Compare with [`expected.txt`](expected.txt).
