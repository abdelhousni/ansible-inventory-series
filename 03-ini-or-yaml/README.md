# 03: INI or YAML for the hosts file

Example for [item 3](https://til.housni.eu/ansible/inventory-ini-or-yaml-hosts-file.html).

| Path | What it shows |
|---|---|
| `hosts/hosts.ini`, `hosts/hosts.yml` | Items 1 and 2's hosts file in both formats: `ansible-inventory --list` gives the same output |
| `inline-vars/host-line.ini` | Eight variables on db1's host line |
| `inline-vars/group-vars-section.ini` | The same eight in a `[postgresql:vars]` section |
| `inline-vars/hosts.yml` | The same eight under db1 in YAML |
| `pitfalls/unquoted-space.ini` | A value with an unquoted space on a host line |
| `types.yml` | Writes each `postgresql_*` variable of db1, with its type |

`run.sh` compares the two hosts files, prints the value and type each
format gives the eight variables, then shows that the broken INI file
leaves an empty inventory, and a playbook that exits 0, unless
`ANSIBLE_INVENTORY_UNPARSED_FAILED=true` (`[inventory]
unparsed_is_failed = true` in `ansible.cfg`).

`.ansible-lint` excludes `inline-vars/hosts.yml`: it writes `True`, `0770`
and `no` on purpose, and ansible-lint's `yaml` rule flags all three.

```sh
./run.sh
```

It needs `jq`. Compare with [`expected.txt`](expected.txt).
