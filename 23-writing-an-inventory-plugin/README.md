# 23: writing an inventory plugin, after the trust order

Example for [item 23](https://til.housni.eu/ansible/inventory-writing-a-plugin-trust-order.html):
look for existing content before writing code, then write a proper inventory
plugin for item 15's CMDB, in a local collection.

`mock/cmdb.py` is a fake CMDB on `127.0.0.1:18230`: `GET /api/servers` answers
`out/servers.json` when the request carries the test-only bearer token
`test-only-token`, and 401 otherwise; `GET /html` answers an HTML page. Each
request is logged to `out/requests.log`.

| Path | What it shows |
|---|---|
| `cmdb/v1.json`, `v2.json`, `no-name.json` | the CMDB's data: before and after a change, and a server without a name |
| `nocode/inventory/` | the no-code way: an inventory script (`01-cmdb.py`) then `ansible.builtin.constructed` (`02-constructed.yml`) |
| `collections/ansible_collections/example/cmdb/` | the plugin's collection: `galaxy.yml`, `meta/runtime.yml`, `plugins/inventory/cmdb.py` |
| `.../tests/unit/` | pytest unit tests, with `open_url` mocked |
| `inventory/hosts.cmdb.yml` | the plugin with `compose`, `keyed_groups`, `strict` and the `jsonfile` cache; token from `CMDB_TOKEN` |
| `pitfalls/env-only.cmdb.yml` | only `plugin:`: the URL and token come from `CMDB_URL` and `CMDB_TOKEN` |
| `pitfalls/cmdb-hosts.yml` | the same file under a name `verify_file()` declines |
| `pitfalls/html.cmdb.yml` | a URL answering HTML instead of JSON |
| `pitfalls/rack.cmdb.yml`, `rack-strict.cmdb.yml` | `keyed_groups` on a missing field, without and with `strict` |
| `ansible.cfg` | `collections_path = collections` |

`run.sh` shows:

1. the inventory plugins ansible-core ships (`ansible-doc -t inventory -l`);
2. the script plus `constructed`: the same groups and variables, no plugin;
3. the plugin's options from `ansible-doc`, with their environment variables;
4. the plugin's inventory and a host's variables, the URL from the
   environment, and a file name `verify_file()` declines (all warnings);
5. each error as an `AnsibleParserError` message: token unset, empty or
   wrong, an HTML answer, a server without a name (and exit 1 with
   `any_unparsed_is_failed`), `keyed_groups` on a missing field with `strict`;
6. the cache after the CMDB changes and once it's down, and `--flush-cache`;
7. the unit tests' summary.

From step 5 on, the warnings that repeat on every failure (the `yaml` and
`ini` plugins declining the file, *No inventory was parsed*) are left out.

```sh
./run.sh
```

It needs ansible-core and pytest (from `requirements.txt`) and port 18230
free. Compare with [`expected.txt`](expected.txt).
