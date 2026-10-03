# 15: a single source of truth

Example for [item 15](https://til.housni.eu/ansible/inventory-plugins-single-source-of-truth.html),
after the Red Hat CoP good practice *Identify your Single Source(s) of Truth
and use it/them in your inventory*.

A mock CMDB, Python's `http.server` on `127.0.0.1:18150`, serves a JSON list
of servers, each with a role and an owner. `run.sh` starts it, swaps its
data, and stops it.

| Path | What it shows |
|---|---|
| `cmdb/v1.json`, `cmdb/v2.json` | the CMDB's data before and after a change: app2 retired, app3 added, db1's owner changed |
| `static/inventory/` | a static inventory copied from `v1.json` by hand: `hosts.yml` and `host_vars/` |
| `script/cmdb_inventory.py` | an inventory script: executable, answers `--list` (with `_meta.hostvars`) and `--host` |
| `plugins/inventory/cmdb.py` | a minimal inventory plugin, with the inventory cache (`Cacheable`) |
| `plugin/hosts.cmdb.yml` | its configuration: `plugin: cmdb`, the URL, `cache: true` with `ansible.builtin.jsonfile` |
| `ansible.cfg` | `inventory_plugins = plugins/inventory`, where Ansible finds the plugin |
| `pitfalls/adjacent/` | the plugin only in `inventory_plugins/` beside a playbook, with no `inventory_plugins` setting |

`run.sh` shows:

1. the three sources give the same inventory, and the plugin's values come
   out marked unsafe in `--list`;
2. after the CMDB changes, the static inventory is stale, the script follows,
   and the plugin returns its cache until `--flush-cache`;
3. the default `enable_plugins` list, and with `-vvv` which plugins declined
   the configuration file before `auto` handed it to `cmdb`;
4. `enable_plugins` without `auto`, with `cmdb` named, and with a typo;
5. `inventory_plugins/` beside a playbook: `ansible-playbook` finds the
   plugin, `ansible-inventory` only with `--playbook-dir`;
6. with the CMDB down: the plugin reads its cache, the script and
   `--flush-cache` give an empty inventory and exit 0, unless
   `any_unparsed_is_failed` is set.

```sh
./run.sh
```

It needs nothing beyond ansible-core and its Python, and port 18150 free.
Compare with [`expected.txt`](expected.txt).
