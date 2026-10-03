# Technique index

The [README](README.md) lists the examples by entry. This page lists them by
the problem they solve, so you can find "how do I…" without opening each
one. Every path is relative to the repository root, and every example runs
with its `run.sh` (see [Running them](README.md#running-them)); CI compares
its output with the example's `expected.txt`.

## Hosts and groups

| To… | Use | Where |
|---|---|---|
| Write an inventory in YAML: hosts, groups, groups inside groups | `all:` with `hosts:` and `children:` | `01-hosts-and-groups/inventory/hosts.yml` |
| Put one host in several groups | list it under each group | `01-hosts-and-groups/inventory/hosts.yml` |
| See the group tree Ansible built | `ansible-inventory --graph` | `01-hosts-and-groups/run.sh` |
| List every group's hosts, or one host's groups, in a playbook | the `groups` and `group_names` magic variables | `01-hosts-and-groups/groups.yml` |
| Find the hosts that belong to no group of their own | `groups['ungrouped']`, or `'ungrouped' in group_names` | `01-hosts-and-groups/groups.yml` |
| Write the hosts file in INI rather than YAML | `[group]`, `[group:children]`; same inventory as YAML | `03-ini-or-yaml/hosts/hosts.ini` |
| Check that two inventories are the same | compare their `ansible-inventory --list` output | `03-ini-or-yaml/run.sh` |
| Run a play on the controller without listing it in the inventory | `hosts: localhost` (the implicit localhost) | `01-hosts-and-groups/groups.yml` |

## Variables in the inventory

| To… | Use | Where |
|---|---|---|
| Keep variables out of the hosts file | an inventory directory with `group_vars/<group>/` | `02-inventory-directory/inventory/` |
| Split a group's variables by role | one file per role, `group_vars/<group>/<role>.yml` | `02-inventory-directory/inventory/group_vars/` |
| Give every host the same connection settings | `group_vars/all/ansible.yml` | `02-inventory-directory/inventory/group_vars/all/ansible.yml` |
| See the variables a host actually gets | `ansible-inventory --host <host>`, or `hostvars[host]` in a play | `02-inventory-directory/run.sh`, `vars.yml` |
| See what type an inventory variable really has | `type_debug` on `hostvars[host][name]` | `03-ini-or-yaml/types.yml` |
| Fail when an inventory source can't be parsed | `ANSIBLE_INVENTORY_UNPARSED_FAILED=true`, or `[inventory] unparsed_is_failed = true` | `03-ini-or-yaml/run.sh` |
| Run every host on the local machine for a test | `ansible_connection: local` with `ansible_playbook_python` | `02-inventory-directory/inventory/group_vars/all/ansible.yml` |

## Connecting to hosts

| To… | Use | Where |
|---|---|---|
| Reach a host by an address other than its inventory name | `ansible_host` | `04-connection-variables/inventory/host_vars/db1/ansible.yml` |
| SSH on another port, as another user | `ansible_port`, `ansible_user` | `04-connection-variables/inventory/host_vars/db1/ansible.yml` |
| Run tasks in a container without SSH | `ansible_connection: community.docker.docker`, `ansible_host` = container name | `04-connection-variables/inventory/host_vars/app1/ansible.yml` |
| Run tasks on the controller | `ansible_connection: local` | `04-connection-variables/inventory/host_vars/jump1/ansible.yml` |
| Check which user and machine a connection really reached | `setup` with `gather_subset: [user, platform]` | `04-connection-variables/whoami.yml` |
| Give each host its connection settings | `host_vars/<host>/ansible.yml` | `04-connection-variables/inventory/host_vars/` |

## Facts and declared variables

| To… | Use | Where |
|---|---|---|
| Declare the state a group should be in (to-be) | a group variable, `group_vars/<group>/<role>.yml` | `07-facts-or-variables/inventory/group_vars/postgresql/postgresql.yml` |
| Find out what a host has installed (as-is) | `ansible.builtin.package_facts`, read as `ansible_facts.packages` | `07-facts-or-variables/drift.yml` |
| Report drift between declared and installed versions | compare `hostvars[host].postgresql_version` with the facts, one line per host | `07-facts-or-variables/drift.yml` |
| Keep facts between runs | `fact_caching = ansible.builtin.jsonfile` with `fact_caching_connection` | `07-facts-or-variables/ansible.cfg` |
| See only the inventory's own host variables, never cached facts | `ansible-inventory --host <host> --export` | `07-facts-or-variables/run.sh` |
| Stop facts from overriding inventory variables of the same name | `inject_facts_as_vars = False`, or `ANSIBLE_INJECT_FACT_VARS=false` | `07-facts-or-variables/run.sh` |

## Pitfalls recorded

Each of these is shown, with its output in the example's `expected.txt`:

- `all` doesn't appear in any host's `group_names`, although every host is
  in `groups['all']` (`01-hosts-and-groups/`).
- The implicit `localhost` is in no group, `all` included
  (`01-hosts-and-groups/groups.yml`).
- `group_vars/<group>.yml` beside `group_vars/<group>/` is never read
  (`02-inventory-directory/pitfalls/file-beside-directory/`).
- A `group_vars/` directory for a misspelled group is ignored without a
  warning (`02-inventory-directory/pitfalls/misspelled-group/`).
- Files in a group directory sort as text: `9-…` comes after `10-…` and wins
  (`02-inventory-directory/pitfalls/file-order/`).
- `~` backups, hidden files and other extensions are skipped; subdirectories
  are read (`02-inventory-directory/pitfalls/skipped-files/`).
- The same `key=value` text gives different types on an INI host line, in an
  INI `:vars` section and in YAML: `true`, `no`, `0770`, `"16"`
  (`03-ini-or-yaml/inline-vars/`).
- An INI `:vars` section doesn't give only strings, despite the docs: numbers,
  lists and dicts come out typed (`03-ini-or-yaml/inline-vars/group-vars-section.ini`).
- An unquoted space on an INI host line drops the whole file: a warning, an
  empty inventory, and a playbook that exits 0 with "no hosts matched"
  (`03-ini-or-yaml/pitfalls/unquoted-space.ini`).
- Without `ansible_host`, the ssh plugin resolves the inventory name:
  *Could not resolve hostname db1* (`04-connection-variables/`).
- Without `ansible_host`, the docker plugin looks for a container named after
  the host, and the error says *Failed to create temporary directory*
  (`04-connection-variables/`).
- The local connection ignores `ansible_user` (`04-connection-variables/`).
- A file without an extension, such as `README`, is parsed as YAML, and the
  error doesn't name it (`02-inventory-directory/pitfalls/readme-without-extension/`).
- With a fact cache, `ansible-inventory --host` shows cached facts as if they
  were inventory variables; `--export` leaves them out, and group variables
  too (`07-facts-or-variables/run.sh`).
- A discovered version written back into `host_vars/` overrides the group's
  declaration, and the drift report says *ok*
  (`07-facts-or-variables/pitfalls/written-back/`).
- A fact injected as a variable beats an inventory variable of the same name:
  `packages` becomes package_facts' dict, with a deprecation warning
  (`07-facts-or-variables/pitfalls/fact-named-like-a-variable/`).
- `package_facts` on Debian or Ubuntu needs `python3-apt` on the host, or it
  fails with *Could not detect a supported package manager*
  (`07-facts-or-variables/containers/`).

## Testing patterns worth reusing

| To… | How | Where |
|---|---|---|
| Test an inventory without any server | every host with `ansible_connection: local` | `01-…`, `02-…` |
| Test SSH and container connections in CI | an sshd container on `127.0.0.1:2222`, a key pair generated per run | `04-connection-variables/run.sh`, `containers/Containerfile` |
| Keep machine-specific names out of `expected.txt` | compare a fact with the controller's own value, print a fixed label | `04-connection-variables/whoami.yml` |
| Show a wrong layout next to the right one | a small inventory per pitfall, printed with `ansible-inventory --host` | `02-inventory-directory/pitfalls/` |
| Test drift against real package databases | one container per version, built from images pinned by digest | `07-facts-or-variables/containers/` |
| Overlay a wrong inventory on the right one | a second `-i` source that adds one variable | `07-facts-or-variables/run.sh`, `pitfalls/` |
| Record a command that's expected to fail, and keep going | `if … ; then … ; else` with the exit code and stderr in the output | `02-inventory-directory/run.sh` |
