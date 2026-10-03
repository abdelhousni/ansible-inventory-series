# 18: constructed on top of a Proxmox source

Example for [item 18](https://til.housni.eu/ansible/inventory-constructed-keyed-groups-compose.html).

`mock/pve.py` is a small read-only mock of the Proxmox VE API on
`127.0.0.1:18180`: five guests on two nodes, modelled on the guests of the
data-shaping series' part 12, with tags, a status, an OS type and a static
IP each. `community.proxmox.proxmox` reads it as an inventory source.

| Path | What it shows |
|---|---|
| `mock/pve.py` | the API endpoints the proxmox inventory plugin calls with a token and `want_facts: true` |
| `inventory/10-pve.proxmox.yml` | the proxmox source: guests as hosts, `proxmox_*` variables and groups |
| `inventory/20-constructed.yml` | `ansible.builtin.constructed` on top: `keyed_groups`, `groups`, `compose`, `use_vars_plugins` |
| `inventory/group_vars/proxmox_pool_pool1/owner.yml` | `owner: team-a` for the guests in pool1, grouped on by the constructed source |
| `variants/defaults.yml` | the same keyed groups without `default_value`, `trailing_separator` and `leading_separator` |
| `direct/` | the same options set on the proxmox plugin itself, with the same `group_vars/` |

`run.sh` starts the mock, prints the groups and variables the proxmox source
builds alone, the keyed groups, conditional groups and `ansible_host`
constructed adds, the keyed groups with the defaults, and the groups the
proxmox plugin builds with the same options, then stops the mock.

```sh
./run.sh
```

It needs `jq`, `python3`, and the `requests` library and community.proxmox
from the lab. Compare with [`expected.txt`](expected.txt).
