# Ansible inventory from scratch: examples

Runnable examples for the **Ansible inventory from scratch** series on
[til.housni.eu](https://til.housni.eu/). Each directory belongs to one entry
of the series, from hosts and groups to dynamic inventory plugins.

| Directory | Entry |
|---|---|
| [`01-hosts-and-groups/`](01-hosts-and-groups/) | [Item 1: Hosts, groups, and the all and ungrouped groups](https://til.housni.eu/ansible/inventory-hosts-groups-all-ungrouped.html) |
| [`02-inventory-directory/`](02-inventory-directory/) | [Item 2: An inventory as a directory, with group_vars per role](https://til.housni.eu/ansible/inventory-directory-group-vars-per-role.html) |
| [`03-ini-or-yaml/`](03-ini-or-yaml/) | [Item 3: INI or YAML for the hosts file](https://til.housni.eu/ansible/inventory-ini-or-yaml-hosts-file.html) |
| [`04-connection-variables/`](04-connection-variables/) | [Item 4: Connection variables, with ssh, docker and local](https://til.housni.eu/ansible/inventory-connection-variables-ssh-docker-local.html) |
| [`05-environments/`](05-environments/) | [Item 5: Environments, separate directories or child groups](https://til.housni.eu/ansible/inventory-environments-directories-or-groups.html) |

Looking for a technique rather than an entry? [INDEX.md](INDEX.md) maps
each problem to the feature that solves it and the file that shows it, with
the pitfalls each example records.

## Running them

Everything runs on the local machine and changes nothing outside the
example's `out/` directory. From the repository root:

```sh
python3 -m venv .venv
.venv/bin/pip install --require-hashes -r requirements.txt
.venv/bin/ansible-galaxy collection install -r requirements.yml -p collections
PATH="$PWD/.venv/bin:$PATH" ./NN-name/run.sh
```

Each example's `run.sh` prints what the entry says, and CI compares that
output with the example's `expected.txt`.

## Related series

The [Shaping data in Ansible](https://github.com/abdelhousni/ansible-data-shaping-series)
examples cover the filters these inventories feed: `hostvars`, `groups` and
`extract`, `groupby`, and building data in one expression.
