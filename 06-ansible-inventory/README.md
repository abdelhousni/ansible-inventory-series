# 06: checking what Ansible sees with ansible-inventory

Example for [item 6](https://til.housni.eu/ansible/inventory-checking-with-ansible-inventory.html).

`inventory/` is items 1 to 4's inventory with three mistakes planted, and
`playbooks/` holds a playbook with a `group_vars/` directory of its own:

| Where | What's wrong | The command that shows it |
|---|---|---|
| `inventory/hosts.yml` | `app3` under `db` instead of `app` | `ansible-inventory --graph` |
| `inventory/group_vars/backups/` | the group is called `backup` | `--graph backups` fails; `--host db1` has no `backup_*` |
| `inventory/group_vars/db/postgresql.yml` | `postgresql_version: "15"` replaces `postgresql`'s `"16"` | `--graph --vars postgresql` |
| `playbooks/group_vars/all/backup.yml` | `backup_keep: 30`, which only playbooks in `playbooks/` see | `--host db1 --playbook-dir playbooks` |

`run.sh` runs `ansible-inventory` with `--graph`, `--vars`, `--list`,
`--yaml`, `--export`, `--limit`, `--output`, `--host`, `--playbook-dir` and
`--toml`, and `playbooks/versions.yml`, which writes what a playbook sees to
`out/versions.txt`. The implicit localhost's interpreter, an absolute path,
is replaced with a fixed label.

```sh
./run.sh
```

Compare with [`expected.txt`](expected.txt). The mistakes are kept on
purpose; fixing them is moving `app3` under `app`, renaming `backups/` to
`backup/`, and deleting `group_vars/db/`.
