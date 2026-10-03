# 14: several inventories at once

Example for [item 14](https://til.housni.eu/ansible/inventory-several-sources-load-order.html).

| Path | What it shows |
|---|---|
| `inventory/10-prod.yml` | the prod hosts, static |
| `inventory/20-staging.py` | the staging hosts from an executable script, standing in for a CMDB or a cloud API |
| `inventory/README.md`, `notes.txt`, `old-run.retry` | files the directory skips by extension |
| `inventory/group_vars/` | every host connects locally |
| `conflicts/` | two sources setting the same group and host variables, on purpose |
| `name-order/` | the same, with the override named `9-override.yml` |
| `environments/prod/`, `environments/staging/` | two directories, each with its own `group_vars/`, combined with two `-i` |
| `pitfalls/not-executable/` | the staging script without its execute bit |
| `pitfalls/readme/` | a `README` with no extension beside the hosts file |

`conflicts/` and `name-order/` keep variables in the sources, against the
series' own advice, because which source wins is what they show.

`run.sh` prints the sources Ansible parsed, in order and with the plugin that
took each (from `-vvv`), the tree, and the files it skipped. Then it shows
which value wins when two sources disagree, file-name and `-i` order, where
`group_vars/` beside each directory applies, and what a non-executable script
and a `README` do to the load.

```sh
./run.sh
```

It needs `python3` for the script. Compare with [`expected.txt`](expected.txt).
