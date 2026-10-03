# 19: when the inventory cache lies

Example for [item 19](https://til.housni.eu/ansible/inventory-cache-stale-data.html):
how an inventory plugin's cache goes stale, and what that does to a play.

It reuses item 15's mock CMDB and plugin, copied here: Python's `http.server`
on `127.0.0.1:18190` serves a JSON list of servers, and `plugins/inventory/cmdb.py`
reads it, with the inventory cache (`Cacheable`). `run.sh` starts the CMDB,
swaps its data, and stops it.

| Path | What it shows |
|---|---|
| `cmdb/v1.json`, `cmdb/v2.json` | the CMDB before and after app2 is decommissioned and app3 added |
| `cmdb/dc2.json` | a second CMDB list, for another datacenter |
| `plugins/inventory/cmdb.py` | item 15's plugin, unchanged |
| `sources/memory.cmdb.yml` | `cache: true` with no `cache_plugin`: the `memory` plugin, unless the fact cache settings name another |
| `sources/jsonfile.cmdb.yml` | `ansible.builtin.jsonfile` in `out/cache`, the default `cache_timeout` of 3600 seconds |
| `sources/short.cmdb.yml` | the same with `cache_timeout: 5` |
| `sources/dc1.cmdb.yml`, `sources/dc2.cmdb.yml` | two sources with the same `cache_connection` and `cache_prefix` |
| `deploy.yml` | a play on `app` that stands for a deployment |
| `record-facts.yml` | stores one fact per host in the fact cache, standing for a run that gathered facts |
| `ansible.cfg` | `inventory_plugins = plugins/inventory`, `forks = 1` |

`run.sh` shows:

1. the `memory` cache follows the CMDB from one run to the next, the
   `jsonfile` cache returns the old hosts;
2. with `cache_timeout: 5`, the cache answers at once, the CMDB 6 seconds
   later; and once the cache has expired, a CMDB that's down gives no hosts,
   exit 0, although the cache file is still there;
3. two sources sharing a cache directory and prefix get one file each, and
   each reads its own; a copy of a configuration file at another path misses
   the cache, the same file named with `./` or an absolute path doesn't;
4. `deploy.yml` on the cached inventory deploys to app2, which the CMDB no
   longer has; with `--flush-cache`, to app3;
5. with the fact cache set to `jsonfile` (`ANSIBLE_CACHE_PLUGIN`,
   `ANSIBLE_CACHE_PLUGIN_CONNECTION`), `memory.cmdb.yml` writes its inventory
   cache there and goes stale; and `--flush-cache` leaves app2's cached facts.

```sh
./run.sh
```

It needs nothing beyond ansible-core and its Python, and port 18190 free. It
sleeps 12 seconds in all. Compare with [`expected.txt`](expected.txt).
