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
| community.docker | 5.3.0 | 04, 07 | `requirements.yml`, installed into `collections/` (below) |
| jq | 1.7 | 03, 08, 09, 10 | your distribution's `jq` package |
| OpenSSH client | 9.6 | 04 | `openssh-client` (Debian, Ubuntu) or `openssh-clients` (Fedora, RHEL) |
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
- **No server is needed.** Examples 01 to 03, 05 to 06, 11 and 12 connect to every
  host locally. 04 and 07 start their targets as Docker containers on the
  local machine, from images pinned by digest, and 04 generates an SSH key
  pair for each run in its `out/` directory.
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
