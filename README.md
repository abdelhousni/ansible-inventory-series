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
| [`06-ansible-inventory/`](06-ansible-inventory/) | [Item 6: Checking what Ansible sees with ansible-inventory](https://til.housni.eu/ansible/inventory-checking-with-ansible-inventory.html) |
| [`07-facts-or-variables/`](07-facts-or-variables/) | [Item 7: Facts or variables, as-is against to-be](https://til.housni.eu/ansible/inventory-facts-or-variables-as-is-to-be.html) |
| [`08-where-variables-live/`](08-where-variables-live/) | [Item 8: Where a variable should live](https://til.housni.eu/ansible/inventory-where-a-variable-should-live.html) |
| [`09-inventory-precedence/`](09-inventory-precedence/) | [Item 9: Inventory precedence, depth and ansible_group_priority](https://til.housni.eu/ansible/inventory-precedence-depth-and-group-priority.html) |
| [`10-secrets-in-the-inventory/`](10-secrets-in-the-inventory/) | [Item 10: Secrets in the inventory, vault.yml and aliases](https://til.housni.eu/ansible/inventory-secrets-vault-yml-aliases.html) |
| [`11-host-patterns/`](11-host-patterns/) | [Item 11: Targeting hosts with patterns, --limit and constructed groups](https://til.housni.eu/ansible/targeting-hosts-static-and-dynamic-inventory.html) |
| [`12-limit-in-practice/`](12-limit-in-practice/) | [Item 12: --limit in practice: plays, run_once, facts of other hosts](https://til.housni.eu/ansible/inventory-limit-in-practice.html) |
| [`13-inventory-is-the-loop/`](13-inventory-is-the-loop/) | [Item 13: Let the inventory be the loop, delegate_to instead of a list of hosts](https://til.housni.eu/ansible/inventory-is-the-loop-delegate-to.html) |
| [`14-several-inventories/`](14-several-inventories/) | [Item 14: Several inventories at once, load order and conflicts](https://til.housni.eu/ansible/inventory-several-sources-load-order.html) |
| [`15-single-source-of-truth/`](15-single-source-of-truth/) | [Item 15: A single source of truth: inventory plugins, enable_plugins and auto](https://til.housni.eu/ansible/inventory-plugins-single-source-of-truth.html) |
| [`16-foreman-inventory/`](16-foreman-inventory/) | [Item 16: The Foreman/Satellite dynamic inventory plugin](https://til.housni.eu/ansible/foreman-dynamic-inventory-plugin.html) |
| [`17-proxmox-inventory/`](17-proxmox-inventory/) | [Item 17: The Proxmox inventory plugin, guests as hosts](https://til.housni.eu/ansible/inventory-proxmox-plugin-guests-as-hosts.html) |
| [`18-constructed/`](18-constructed/) | [Item 18: ansible.builtin.constructed: keyed_groups, groups and compose on top of another source](https://til.housni.eu/ansible/inventory-constructed-keyed-groups-compose.html) |
| [`19-inventory-cache-stale-data/`](19-inventory-cache-stale-data/) | [Item 19: When the inventory cache lies: stale hosts, cache_timeout and --flush-cache](https://til.housni.eu/ansible/inventory-cache-stale-data.html) |
| [`20-inventory-cache-performance/`](20-inventory-cache-performance/) | [Item 20: The inventory cache for speed, request counts and timeouts](https://til.housni.eu/ansible/inventory-cache-performance.html) |
| [`21-add-host/`](21-add-host/) | [Item 21: add_host, provision then configure in one run](https://til.housni.eu/ansible/inventory-add-host-provision-then-configure.html) |
| [`22-group-by/`](22-group-by/) | [Item 22: Groups from facts with group_by](https://til.housni.eu/ansible/inventory-group-by.html) |
| [`23-writing-an-inventory-plugin/`](23-writing-an-inventory-plugin/) | [Item 23: Writing an inventory plugin, after the trust order](https://til.housni.eu/ansible/inventory-writing-a-plugin-trust-order.html) |
| [`24-inventory-in-aap/`](24-inventory-in-aap/) | [Item 24: Inventory in AAP: sources from a project, smart and constructed inventories](https://til.housni.eu/ansible/inventory-in-aap-sources-smart-constructed.html) |

Looking for a technique rather than an entry? [INDEX.md](INDEX.md) maps
each problem to the feature that solves it and the file that shows it, with
the pitfalls each example records.

## Running them

From the repository root, once the lab below is in place:

```sh
./lab/check.sh                                 # reports anything missing
PATH="$PWD/.venv/bin:$PATH" ./NN-name/run.sh
```

Each example's `run.sh` prints what the entry says, and CI compares that
output with the example's `expected.txt`. It writes only to the example's
`out/` directory, except the Docker examples (04, 07), which also build
images and start containers. They remove their containers when they end;
the images stay, and `docker image rm inv04-target inv07-db1 inv07-db2`
removes them.

## Local lab

What the examples need, and how to set it up on your own machine. This is
the setup the entries were tested with, on Ubuntu 24.04; GitHub's
`ubuntu-24.04` runner, where CI runs, provides the same.

| What | Version tested | Needed by | How |
|---|---|---|---|
| Python | 3.12 | every example | your distribution's `python3.12`; ansible-core 2.21 needs 3.12 or newer |
| ansible-core | 2.21.4 | every example | in a virtualenv, from the locked `requirements.txt` (below) |
| requests (Python) | 2.34.2 | 16, 17, 18, 20 | in the same virtualenv, from `requirements.txt`; the Foreman and Proxmox inventory plugins import it |
| pytest (Python) | 9.1.1 | 23 | in the same virtualenv, from `requirements.txt`; runs the plugin's unit tests |
| community.docker | 5.3.0 | 04, 07 | `requirements.yml`, installed into `collections/` (below) |
| theforeman.foreman | 5.13.0 | 16 | `requirements.yml`, installed into `collections/` (below) |
| jq | 1.7 | 03, 08, 09, 10, 16, 18, 24 | your distribution's `jq` package |
| community.general | 13.4.0 | 17 (the redirect pitfall) | `requirements.yml`, installed into `collections/` |
| community.proxmox | 2.0.0 | 17, 18, 20 | `requirements.yml`, installed into `collections/` |
| OpenSSH client | 9.6 | 04, 13 | `openssh-client` (Debian, Ubuntu) or `openssh-clients` (Fedora, RHEL) |
| Docker Engine | 29.6 | 04, 07 | Docker Engine or Docker Desktop, with the daemon running and your user allowed to use it |

```sh
python3.12 -m venv .venv
.venv/bin/pip install --require-hashes -r requirements.txt
.venv/bin/ansible-galaxy collection install -r requirements.yml -p collections
./lab/check.sh
```

- **The virtualenv** holds exactly the packages in `requirements.txt`, with
  their hashes. It's compiled from `requirements.in` with uv; CI's `lock`
  job fails if the two drift apart.
- **`collections/`** is next to the examples, and each example's
  `ansible.cfg` points at it, so nothing is installed in your home
  directory.
- **No server is needed.** Examples 01 to 03, 05 to 06, 11 to 14, 21, 22 and
  24 connect to every host locally. 15 to 20 and 23 start their own mock APIs,
  small Python servers on `127.0.0.1` (a CMDB on port 18150, a Foreman on
  18160, Proxmox VE on 18170, 18180 and 18200, CMDBs on 18190 and 18230), and
  stop them when they end. 04 and 07 start their targets as Docker containers
  on the local machine, from images pinned by digest, and 04 generates an SSH
  key pair for each run in its `out/` directory.
- **`lab/check.sh`** checks each line of the table and prints the command
  for whatever is missing. It changes nothing.

Two things to know:

- **Podman instead of Docker is untested.** The examples call the `docker`
  command, and the `community.docker.docker` connection plugin does too.
  Podman's `docker` compatibility package may work; the entries weren't
  tested with it.
- **"Ansible requires blocking IO on stdin/stdout/stderr"**: some terminals
  and sandboxes hand Ansible non-blocking output, and it refuses to run.
  The `run.sh` scripts send Ansible's output to files, which avoids it.
  To run a playbook by hand in such an environment, redirect its output to
  a file too.

## Related series

The [Shaping data in Ansible](https://github.com/abdelhousni/ansible-data-shaping-series)
examples cover the filters these inventories feed: `hostvars`, `groups` and
`extract`, `groupby`, and building data in one expression.
