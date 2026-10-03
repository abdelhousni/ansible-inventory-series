# 02: an inventory as a directory

Example for [item 2](https://til.housni.eu/ansible/inventory-directory-group-vars-per-role.html).

`inventory/` holds item 1's hosts file, still without variables, and a
`group_vars/` directory with one directory per group and one file per role:

```
inventory/
├── hosts.yml
└── group_vars/
    ├── all/connection.yml
    ├── app/podman.yml
    ├── backup/backup.yml
    └── postgresql/postgresql.yml
```

`vars.yml` writes the role variables each host gets to `out/vars.txt`.

`pitfalls/` holds five small inventories, each wrong on purpose, and
`run.sh` prints what `ansible-inventory --host db1` makes of each:

| Directory | What's wrong | What Ansible does |
|---|---|---|
| `file-beside-directory/` | `group_vars/postgresql.yml` next to `group_vars/postgresql/` | reads the directory, ignores the file |
| `misspelled-group/` | `group_vars/postgres/`, for a group called `postgresql` | ignores it, with no warning |
| `file-order/` | `9-base.yml` and `10-upgrade.yml` set the same variable | `9-base.yml` wins: names sort as text |
| `skipped-files/` | a `~` backup, a hidden file, a `.md` file, a subdirectory | skips the first three, reads the subdirectory |
| `readme-without-extension/` | a `README` with no extension | parses it as YAML, and fails without naming the file |

```sh
./run.sh
```

Compare with [`expected.txt`](expected.txt).
