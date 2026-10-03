# 22: groups from facts with group_by

Example for [item 22](https://til.housni.eu/ansible/inventory-group-by.html):
`ansible.builtin.group_by` puts hosts in groups named after a fact, during
the run, and those groups bring their `group_vars/`.

Every host runs on this machine, so gathering facts would give each one the
same distribution. Instead, `facts/` holds recorded facts for five hosts, in
the format the `jsonfile` fact cache of ansible-core 2.21 writes (an `s1_`
prefix, the facts as a JSON string under `__payload__`). `run.sh` copies them
to `out/facts/`, which `ansible.cfg` sets as the cache, with
`fact_caching_timeout = 0` so they never expire. The values are the ones
`setup` reports on each distribution (`distribution` and `os_family`, as
mapped in ansible-core's `module_utils/facts/system/distribution.py`). `lb2`
has no facts, as a host that couldn't be reached. Re-record them if a later
ansible-core changes the cache format.

| Path | What it shows |
|---|---|
| `inventory/hosts.yml` | six hosts in `web`, `db` and `lb`, no OS groups |
| `inventory/group_vars/os_<family>/` | `package_manager` for groups that only `group_by` creates |
| `facts/` | the recorded facts |
| `group-by.yml` | `group_by` on `os_<family>` with `parents: by_os`, then on the sanitised distribution and major version under it; a play on `os_RedHat` |
| `groups.txt.j2` | records each host's `group_names` |
| `pitfalls/spaces.yml` | a key with a space, unsanitised |
| `pitfalls/no-default.yml` | a key with no default for a host without facts |
| `keyed/constructed.yml` | the same `os_` groups from constructed's `keyed_groups` |

`run.sh` prints the facts, runs `group-by.yml` on every host, with
`--limit web1,db1` and with `--limit os_RedHat`, checks what's left after
the run, runs both pitfalls, then shows the `keyed_groups` version.

```sh
./run.sh
```

No server or container is needed. Compare with [`expected.txt`](expected.txt).
