# 16: the Foreman/Satellite inventory plugin

Example for [item 16](https://til.housni.eu/ansible/foreman-dynamic-inventory-plugin.html):
`theforeman.foreman.foreman` against a fake Foreman.

`mock/foreman.py` is a small Python HTTP server on `127.0.0.1:18160` that
answers with the JSON files under `mock/`, and logs each request to
`out/requests.log`. The answers are three hosts in two nested host groups,
two locations and one organization, with host parameters, facts and host
collections. They're shaped after the plugin's source (which fields it reads)
and Foreman's API v2, not recorded from a live server. Under `/plain/`, the
same server acts as a Foreman without the `foreman_ansible` plugin: every
`/ansible/` URL answers 404.

| Path | What it shows |
|---|---|
| `inventory/hosts-api.foreman.yml` | the Hosts API with parameters, facts and host collections, plus `hostnames`, `compose`, `keyed_groups` and `groups` |
| `inventory/legacy.foreman.yml` | `legacy_hostvars: true` and `group_prefix: fm_` |
| `inventory/reports-api.foreman.yml` | the Reports API, the default |
| `inventory/cached.foreman.yml` | the inventory cache in `out/cache/`, with the `jsonfile` cache plugin |
| `params.yml` | a play reading `foreman_params` with `dict2items` |
| `pitfalls/no-foreman-ansible.foreman.yml` | the Reports API on a Foreman without `foreman_ansible` |
| `pitfalls/foreman-inventory.yml` | a file name that doesn't end in `foreman.yml` |
| `mock/` | the fake Foreman and its answers |

`run.sh` starts the fake Foreman and stops it when it ends. For each
configuration it prints the graph or a host's variables, and the requests
the plugin sent, counted. It then shows the cache answering a second run
without any request, and the two pitfalls. The user and password come from
`FOREMAN_USER` and `FOREMAN_PASSWORD`, set by `run.sh` to test-only values
the fake Foreman doesn't check.

```sh
./run.sh
```

It needs `theforeman.foreman` in `../collections/`, the `requests` Python
library in the virtualenv, `jq`, and port 18160 free. Compare with
[`expected.txt`](expected.txt).
