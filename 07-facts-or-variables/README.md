# 07: facts or variables

Example for [item 7](https://til.housni.eu/ansible/inventory-facts-or-variables-as-is-to-be.html).

The inventory declares the PostgreSQL major version the `postgresql` group
should run (to-be), in `inventory/group_vars/postgresql/postgresql.yml`:
`postgresql_version: 16`. Two containers report what they actually have
installed (as-is):

| Host | Image | Installed |
|---|---|---|
| `db1` | `ubuntu:24.04` | `postgresql-client-16` |
| `db2` | `debian:bookworm-slim` | `postgresql-client-15` |

`run.sh` needs Docker. It builds both images from `containers/`, starts the
containers, and:

1. prints the variables `ansible-inventory --host db1` gives before any play;
2. runs `drift.yml`, which gathers `ansible_facts.packages` with
   `package_facts` and writes one line per host: declared, installed, *ok* or
   *drift*;
3. prints `ansible-inventory --host db1` again, now that `ansible.cfg`'s
   jsonfile fact cache holds db1's facts, and with `--export`;
4. reruns `drift.yml` with `pitfalls/written-back/` added as a second
   inventory source: db2's installed version written into its `host_vars`;
5. runs `packages.yml` with `pitfalls/fact-named-like-a-variable/` added: an
   inventory variable called `packages`, the name of package_facts' fact,
   with fact injection on (the default) and off.

The images install `python3-apt`: without it, `package_facts` can't read
the apt database.

```sh
./run.sh
```

Compare with [`expected.txt`](expected.txt).
