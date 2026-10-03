# 01: hosts, groups, and the all and ungrouped groups

Example for [item 1](https://til.housni.eu/ansible/inventory-hosts-groups-all-ungrouped.html).

`inventory/hosts.yml` lists the PostgreSQL server `db1`, three application
servers and a jump host, `jump1`, that belongs to no group of its own.
`db1` is in `db`, in `postgresql` through `db`, and in `backup`. The hosts
file has no variables; the connection settings are in
`inventory/group_vars/all/connection.yml`, and every host runs on the
local machine.

`run.sh` prints `ansible-inventory --graph`, then runs `groups.yml`, which
records the `groups` mapping and each host's `group_names`.

```sh
./run.sh
```

Compare with [`expected.txt`](expected.txt).
