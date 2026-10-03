# 20: the inventory cache for speed

Example for [item 20](https://til.housni.eu/ansible/inventory-cache-performance.html):
what `cache: true` saves on a large Proxmox VE inventory, counted in API
requests, and what happens when the API is slow or down. It reuses the
Proxmox API mock of [item 17](../17-proxmox-inventory/), with a generated
fixture: two nodes, `pve` and `pve2`, and 120 guests, half of them tagged
`web`. Every response waits 20 ms, as a remote API would.

| Path | What it shows |
|---|---|
| `mock/server.py` | item 17's mock, plus a latency per request and a per-path delay; logs each request |
| `mock/generate.py` | writes the mock's responses: 120 guests, VMs and containers, a third of them running |
| `inventory/list.proxmox.yml` | the `web` guests from the guest lists alone |
| `inventory/facts.proxmox.yml` | the same with `want_facts`: the configuration of all 120 guests is read |
| `inventory/post-filter-facts.proxmox.yml` | the same with `want_post_filter_facts`: only the 60 kept guests |
| `inventory/cached.proxmox.yml` | the post-filter inventory with `cache: true`, the `jsonfile` plugin, `cache_timeout: 3600` |
| `pitfalls/memory-cache.proxmox.yml` | `cache: true` with the default `memory` plugin |
| `pitfalls/slow-api.proxmox.yml` | a second mock whose `/nodes` answers 3 seconds late |

`run.sh` generates the fixture, starts the two mocks and shows:

1. the requests one run makes with no facts, `want_facts` and
   `want_post_filter_facts`;
2. the cache: a cold run, a warm run (the ticket request only),
   `--flush-cache`, a cache file older than `cache_timeout`, and the
   `memory` plugin, which saves nothing between runs;
3. wall time, as checks that can't flake: the uncached run takes at least
   requests × 20 ms, the cached one less than half of it;
4. the slow API, waited for, then cut by `timeout 2`; the API down with a
   warm cache, with a password and with an API token.

```sh
./run.sh
```

It needs community.proxmox in `../collections/`, `requests` in the
virtualenv, `timeout` (GNU coreutils), and ports 18200 and 18201 free. It
takes about a minute. Compare with [`expected.txt`](expected.txt).
