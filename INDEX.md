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
- A file without an extension, such as `README`, is parsed as YAML, and the
  error doesn't name it (`02-inventory-directory/pitfalls/readme-without-extension/`).

## Testing patterns worth reusing

| To… | How | Where |
|---|---|---|
| Test an inventory without any server | every host with `ansible_connection: local` | `01-…`, `02-…` |
| Show a wrong layout next to the right one | a small inventory per pitfall, printed with `ansible-inventory --host` | `02-inventory-directory/pitfalls/` |
| Record a command that's expected to fail, and keep going | `if … ; then … ; else` with the exit code and stderr in the output | `02-inventory-directory/run.sh` |
