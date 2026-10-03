# 09: inventory precedence

Example for [item 9](https://til.housni.eu/ansible/inventory-precedence-depth-and-group-priority.html).

db1 and db2 are in `db`, a child of `postgresql`, and in `backup`, a sibling
of `postgresql`. Every value is read with `ansible-inventory --host`.

| Path | What it shows |
|---|---|
| `levels/` | `postgresql_max_connections` in `all` (10), `postgresql` (20), `backup` (40), `db` (30) and `host_vars/db1` (50); `run.sh` removes the winning level each time. `postgresql_conf`, a dict, in `all` and `postgresql`. |
| `priority/same-depth/` | `ansible_group_priority: 10` on `backup` beats `postgresql`, at the same depth |
| `priority/across-depths/` | the same priority loses to `db`, one level deeper |
| `conflict/before/` | db1 needs `postgresql_wal_level: replica` from `backup`, and gets `minimal` from `db` |
| `conflict/priority-only/` | adding `ansible_group_priority` to `backup` changes nothing |
| `conflict/restructured/` | `backup` moved under `postgresql`, at `db`'s depth, where its priority applies |

`ansible_group_priority` sits in the hosts files on purpose: Ansible reads
it only in an inventory source, not in `group_vars/`.

```sh
./run.sh
```

It needs `jq`. Compare with [`expected.txt`](expected.txt).
