# 11: targeting hosts with patterns

Example for [item 11](https://til.housni.eu/ansible/targeting-hosts-static-and-dynamic-inventory.html).

| Path | What it shows |
|---|---|
| `inventory/10-hosts.yml` | prod and staging hosts, grouped by function (`app`, `db`) and by environment (`prod`, `staging`) |
| `inventory/20-extra.yml` | a second source that adds `app3` to `app`, without an environment |
| `inventory/30-constructed.yml` | `ansible.builtin.constructed` building `env_prod` and `env_staging` from `env` |
| `inventory/group_vars/` | `env` per environment; every host connects locally |
| `pitfalls/strict/` | the same inventory with `strict: true` |
| `limit.txt` | a host list for `--limit @limit.txt` |
| `site.yml` | a play on `hosts: app` that prints the hosts it reached |

`run.sh` lists the hosts each pattern matches with `ansible --list-hosts`:
unions, intersections, exclusions, the order Ansible applies them in,
indexes, wildcards and regexes. Then it adds the second source, uses the
constructed groups, shows what `strict: true` does with a host that has no
`env`, narrows `site.yml` with `--limit`, and prints the tree.

```sh
./run.sh
```

Compare with [`expected.txt`](expected.txt).
