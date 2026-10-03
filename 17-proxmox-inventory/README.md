# 17: the Proxmox inventory plugin, guests as hosts

Example for [item 17](https://til.housni.eu/ansible/inventory-proxmox-plugin-guests-as-hosts.html):
`community.proxmox.proxmox` turns the guests of a Proxmox VE cluster, its
QEMU VMs and LXC containers, into hosts, here against a local mock of the
Proxmox API rather than a real cluster.

The guests are those of parts 4 and 12 of the data-shaping series, with tags
added: two nodes, `pve` and `pve2`, two VMs, four containers (two of them
named `test-lxc.home.arpa`, one with no name), and a VM template.

| Path | What it shows |
|---|---|
| `mock/server.py` | a fake Proxmox VE API on `127.0.0.1:18170`: a ticket for any password, recorded responses, a log of each request |
| `mock/api.json` | the responses, by path under `/api2/json`: nodes, guests, their status, configuration, snapshots, interfaces, the pool `pool1` |
| `inventory/guests.proxmox.yml` | every named guest and node, in the plugin's default groups |
| `inventory/running-test.proxmox.yml` | `filters:` on status and tag, without `want_facts` |
| `inventory/facts.proxmox.yml` | `want_facts`, `ansible_host` with `compose:`, a group per tag with `keyed_groups:` |
| `inventory/post-filter-facts.proxmox.yml` | the same with `want_post_filter_facts`: same inventory, fewer requests |
| `pitfalls/unnamed.proxmox.yml` | no filter: the guest with no name breaks the whole source |
| `pitfalls/redirect.proxmox.yml` | `plugin: community.general.proxmox`, the name before the move |
| `pitfalls/tags-parsed.proxmox.yml` | a filter on a fact that only `want_facts` gives |

`run.sh` starts the mock, prints the plugin's groups, the variables of the
duplicate name, the filtered hosts, the number of API requests with and
without facts, the composed `ansible_host` and tag groups, and the three
empty inventories that still exit 0. It stops the mock when it ends.

```sh
./run.sh
```

It needs community.proxmox and community.general in `../collections/`, and
`requests` in the virtualenv. Compare with [`expected.txt`](expected.txt).

To reuse the mock for another example, copy `mock/` and edit `api.json`;
`mock/server.py PORT LOG [API_JSON]` takes another file as third argument.
