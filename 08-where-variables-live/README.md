# 08: where a variable should live

Example for [item 8](https://til.housni.eu/ansible/inventory-where-a-variable-should-live.html).

`roles/pgconf` renders a `postgresql.conf` per host into `out/`. Its
defaults (`defaults/main.yml`) hold every setting, and a safety switch,
`pgconf_allow_restart: false`.

| Path | What it shows |
|---|---|
| `messy/` | Settings in the play's `vars:`, a `set_fact` for db1, the port given with `-e`. A `group_vars/postgresql` file tries to set `max_connections` to 300 and loses to the play. Wrong on purpose. |
| `tidy/` | The same result, with the settings in role defaults, `group_vars/postgresql` and `host_vars/db1`. The playbook only applies the role. |
| `adjacent/` | The tidy playbook with a `group_vars/` directory beside it (250): it beats the inventory's `group_vars` (200), and `ansible-inventory` only shows it with `--playbook-dir`. `roles/pgconf/group_vars/` (999) is never read. |
| `roles/pgconf_constants/` | A role with `max_connections` in `vars/main.yml`: it beats the inventory's 300. Only an extra var gets past it. Wrong on purpose. |

`run.sh` renders both versions, prints what `ansible-inventory --host db1`
shows for each, runs the tidy version once with the safety switch on
(`-e pgconf_allow_restart=true`), then shows the `vars/` role's value
against the inventory and against `-e`.

```sh
./run.sh
```

Compare with [`expected.txt`](expected.txt).
