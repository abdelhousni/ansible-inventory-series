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

## Environments

| To… | Use | Where |
|---|---|---|
| Keep prod and staging apart, chosen with `-i` | one inventory directory per environment, same group names | `05-environments/inventories/` |
| Keep both environments in one inventory | `prod`/`staging` groups beside functional groups (`app`, `db`) | `05-environments/single/hosts.yml` |
| Run a play on one environment of a single inventory | `--limit staging`, or `hosts: app:&staging` | `05-environments/run.sh`, `app_staging.yml` |
| Give the environment's value precedence over a functional group's | rely on name order, or `ansible_group_priority` in the hosts file | `05-environments/precedence/` |
## Checking what Ansible sees

| To… | Use | Where |
|---|---|---|
| Find a host in the wrong group | `ansible-inventory --graph`, or `--graph <group>` for one branch | `06-ansible-inventory/run.sh` |
| Check that a group exists before blaming its `group_vars/` | `ansible-inventory --graph <group>` fails for an unknown group | `06-ansible-inventory/run.sh` |
| See which group sets a variable, and which value wins | `ansible-inventory --graph --vars <group>` | `06-ansible-inventory/run.sh` |
| See the merged variables of one host | `ansible-inventory --host <host>` | `06-ansible-inventory/run.sh` |
| See variables per group, as they're written | `ansible-inventory --list --export` | `06-ansible-inventory/run.sh` |
| Dump the inventory as YAML, or to a file | `--list --yaml`, `--list --output <file>` | `06-ansible-inventory/run.sh` |
| Include the `group_vars/` beside a playbook | `ansible-inventory --playbook-dir <dir>` | `06-ansible-inventory/run.sh` |
## Facts and declared variables

| To… | Use | Where |
|---|---|---|
| Declare the state a group should be in (to-be) | a group variable, `group_vars/<group>/<role>.yml` | `07-facts-or-variables/inventory/group_vars/postgresql/postgresql.yml` |
| Find out what a host has installed (as-is) | `ansible.builtin.package_facts`, read as `ansible_facts.packages` | `07-facts-or-variables/drift.yml` |
| Report drift between declared and installed versions | compare `hostvars[host].postgresql_version` with the facts, one line per host | `07-facts-or-variables/drift.yml` |
| Keep facts between runs | `fact_caching = ansible.builtin.jsonfile` with `fact_caching_connection` | `07-facts-or-variables/ansible.cfg` |
| See only the inventory's own host variables, never cached facts | `ansible-inventory --host <host> --export` | `07-facts-or-variables/run.sh` |
| Stop facts from overriding inventory variables of the same name | `inject_facts_as_vars = False`, or `ANSIBLE_INJECT_FACT_VARS=false` | `07-facts-or-variables/run.sh` |

## Where variables live

| To… | Use | Where |
|---|---|---|
| Give a role setting a value everyone may override | `defaults/main.yml` in the role | `08-where-variables-live/roles/pgconf/defaults/main.yml` |
| Set the desired state for a group, or for one host | `group_vars/<group>/<role>.yml`, `host_vars/<host>/<role>.yml` | `08-where-variables-live/tidy/inventory/` |
| Move settings out of a playbook | play `vars:`, `set_fact` and `-e` replaced by defaults and inventory variables | `08-where-variables-live/messy/` → `tidy/` |
| Guard a dangerous step with an extra var | a default `false` switch, turned on with `-e` for one run, tested with `\| bool` | `08-where-variables-live/roles/pgconf/` |

## Inventory precedence

| To… | Use | Where |
|---|---|---|
| Know which inventory level wins | host, then the deepest group, then groups of the same depth by name (`ansible_group_priority` first), then `all` | `09-inventory-precedence/levels/` |
| Break a tie between groups at the same depth | `ansible_group_priority` in the hosts file | `09-inventory-precedence/priority/same-depth/` |
| Find which group gave a host its value | `ansible-inventory --graph --vars`: the group's own value is listed after its hosts, the host's merged value nested under the host | `09-inventory-precedence/conflict/before/` |
| Let a group win over a deeper one | move it to the same depth, then give it `ansible_group_priority` | `09-inventory-precedence/conflict/restructured/` |

## Secrets

| To… | Use | Where |
|---|---|---|
| Keep a secret in the inventory and still find where it's used | `vars.yml` with `name: "{{ vault_name }}"` next to an encrypted `vault.yml` | `10-secrets-in-the-inventory/alias/inventory/group_vars/postgresql/` |
| Encrypt one value inside a plaintext file | `ansible-vault encrypt_string … --name <var>` | `10-secrets-in-the-inventory/inline/` |
| Keep secrets out of task output | `no_log: true` on the task that uses them | `10-secrets-in-the-inventory/use.yml` |
| Use different passwords per environment | `ansible-vault encrypt --vault-id prod@file`, then `--vault-id` per ID | `10-secrets-in-the-inventory/vault-ids/` |
| Change a vault password | `ansible-vault rekey --new-vault-password-file` | `10-secrets-in-the-inventory/run.sh` |

## Targeting hosts

| Problem | Feature | Where |
|---|---|---|
| Run on hosts in two groups, in both, or in one but not the other | `app:db`, `app:&prod`, `app:!staging` | `11-host-patterns/run.sh` |
| Pick hosts by position or by name | `app[0]`, `app[1:]`, `stg-*`, `~^(app\|db)\d$` | `11-host-patterns/run.sh` |
| Narrow a playbook's hosts without editing it | `--limit staging`, `--limit @limit.txt` | `11-host-patterns/site.yml`, `limit.txt` |
| Add hosts from a second file | several sources in one inventory directory, read in name order | `11-host-patterns/inventory/20-extra.yml` |
| Group hosts by a variable's value | `ansible.builtin.constructed` with `keyed_groups` and `use_vars_plugins: true` | `11-host-patterns/inventory/30-constructed.yml` |
| Read another host's facts when `--limit` leaves it out | `setup` with `delegate_to` and `delegate_facts: true`, or a fact cache | `12-limit-in-practice/delegate-facts.yml`, `run.sh` |
| Know inside a play whether a limit is set | the `ansible_limit` magic variable | `12-limit-in-practice/facts.yml` |
| Act on a manager for each host, such as creating VMs | a play on the hosts with `delegate_to: "{{ vm_manager }}"`, not a loop over a list | `13-inventory-is-the-loop/provision-good.yml` |
| Size hosts by group, with exceptions per host | `group_vars/<group>/` and `host_vars/<host>/`, read by the delegated play | `13-inventory-is-the-loop/good/` |

## Several inventory sources

| Problem | Feature | Where |
|---|---|---|
| Mix static hosts and a script (CMDB, cloud API) in one inventory | one directory holding a YAML file and an executable script | `14-several-inventories/inventory/` |
| See which sources Ansible parsed, in which order, with which plugin | `ansible-inventory --graph -vvv`, lines *Parsed … inventory source with … plugin* | `14-several-inventories/run.sh` |
| Override a source's values with another source | a later source: last loaded wins, key by key; groups merge | `14-several-inventories/conflicts/` |
| Combine two inventory directories in one run | `-i dir1 -i dir2`, loaded in the order given | `14-several-inventories/environments/` |
| Keep notes or leftovers in an inventory directory | `.md`, `.txt`, `.retry`, `.cfg`, `.orig`, `~`, hidden files are skipped (`inventory_ignore_extensions`) | `14-several-inventories/inventory/` |
| Fail when any source in a directory can't be parsed | `ANSIBLE_INVENTORY_ANY_UNPARSED_IS_FAILED=true`, or `[inventory] any_unparsed_is_failed` | `14-several-inventories/run.sh` |

## Inventory from the system that owns the data

| Problem | Feature | Where |
|---|---|---|
| Read hosts from a CMDB or another API instead of copying them | an inventory plugin with a YAML configuration file (`plugin: <name>`) | `15-single-source-of-truth/plugin/hosts.cmdb.yml` |
| Write a small inventory plugin | `BaseInventoryPlugin`, `verify_file()` on the file name, `parse()` with `_read_config_data()` | `15-single-source-of-truth/plugins/inventory/cmdb.py` |
| Make Ansible find a plugin of your own | `inventory_plugins = <dir>` in `ansible.cfg` | `15-single-source-of-truth/ansible.cfg` |
| Write an inventory script | an executable answering `--list` with `_meta.hostvars`, and `--host` | `15-single-source-of-truth/script/cmdb_inventory.py` |
| See which plugin parsed a source, and which declined it | `ansible-inventory -vvv` | `15-single-source-of-truth/run.sh` |
| Change which inventory plugins run, and in what order | `[inventory] enable_plugins`, or `ANSIBLE_INVENTORY_ENABLED` | `15-single-source-of-truth/run.sh` |
| Keep the inventory when the source is down, and save API calls | `cache: true`, `cache_plugin: ansible.builtin.jsonfile`, `Cacheable` in the plugin | `15-single-source-of-truth/plugin/hosts.cmdb.yml` |
| Refresh a cached inventory | `--flush-cache` | `15-single-source-of-truth/run.sh` |
| Fail when a source can't be read, rather than run on an empty inventory | `ANSIBLE_INVENTORY_ANY_UNPARSED_IS_FAILED=true`, or `[inventory] any_unparsed_is_failed` | `15-single-source-of-truth/run.sh` |

## The inventory cache

| Problem | Feature | Where |
|---|---|---|
| Keep a plugin's inventory between runs | `cache_plugin: ansible.builtin.jsonfile` with `cache_connection`; the default `memory` lasts one run | `19-inventory-cache-stale-data/sources/jsonfile.cmdb.yml` |
| Bound how stale a cached inventory can be | `cache_timeout` (seconds, default 3600), checked against the cache file's age | `19-inventory-cache-stale-data/sources/short.cmdb.yml` |
| Share one cache directory between several sources | same `cache_connection` and `cache_prefix`: one file per plugin and configuration file path | `19-inventory-cache-stale-data/sources/dc1.cmdb.yml` |
| Run a play on the source's current hosts, not the cached ones | `ansible-playbook --flush-cache` | `19-inventory-cache-stale-data/run.sh` |

## Foreman and Satellite

| Problem | Feature | Where |
|---|---|---|
| Take the hosts from Foreman or Satellite | `theforeman.foreman.foreman` in a file ending in `foreman.yml`, loaded by `auto` | `16-foreman-inventory/inventory/hosts-api.foreman.yml` |
| Keep the Foreman password out of the source file | `FOREMAN_USER` and `FOREMAN_PASSWORD` in the environment | `16-foreman-inventory/run.sh` |
| Get Foreman's host parameters as variables | `want_params: true`; with `legacy_hostvars: true`, a `foreman_params` dict, looped over with `dict2items` | `16-foreman-inventory/inventory/`, `params.yml` |
| Groups by location with the Hosts API | `keyed_groups` on `foreman_location_name` | `16-foreman-inventory/inventory/hosts-api.foreman.yml` |
| Short host names instead of FQDNs | `hostnames: [name.split('.')[0]]` | `16-foreman-inventory/inventory/` |
| Stop asking Foreman on every run | `cache: true` with `cache_plugin: ansible.builtin.jsonfile`; `--flush-cache` to ask again | `16-foreman-inventory/inventory/cached.foreman.yml` |

## Dynamic inventory from Proxmox VE

| To… | Use | Where |
|---|---|---|
| Make each Proxmox guest a host | `community.proxmox.proxmox`, a `*.proxmox.yml` file | `17-proxmox-inventory/inventory/guests.proxmox.yml` |
| Target guests by node, type, status or pool | the plugin's groups: `proxmox_<node>_<type>`, `proxmox_all_running`, `proxmox_pool_<pool>` | `17-proxmox-inventory/run.sh` |
| Keep only some guests | `filters:` on `proxmox_status` and `proxmox_tags`, without `want_facts` | `17-proxmox-inventory/inventory/running-test.proxmox.yml` |
| Get each guest's configuration as variables | `want_facts: true`, or `want_post_filter_facts: true` for fewer API calls | `17-proxmox-inventory/inventory/facts.proxmox.yml`, `post-filter-facts.proxmox.yml` |
| Set `ansible_host` from the guest agent or the static IP | `compose:` over `proxmox_agent_interfaces`, `proxmox_ipconfig0`, `proxmox_net0` | `17-proxmox-inventory/inventory/facts.proxmox.yml` |
| A group per Proxmox tag | `keyed_groups:` on `proxmox_tags_parsed` | `17-proxmox-inventory/inventory/facts.proxmox.yml` |
| Fail when a source doesn't parse | `ANSIBLE_INVENTORY_ANY_UNPARSED_IS_FAILED=true` (`any_unparsed_is_failed`) | `17-proxmox-inventory/run.sh` |

## Constructed groups and variables

| Problem | Feature | Where |
|---|---|---|
| Turn Proxmox VE guests into hosts | `community.proxmox.proxmox` in a `*.proxmox.yml` source, `want_facts: true` | `18-constructed/inventory/10-pve.proxmox.yml` |
| One group per tag, and one for guests without tags | `keyed_groups` on a list, `default([''])` with `default_value` | `18-constructed/inventory/20-constructed.yml` |
| Group names without a leading `_` when the prefix is empty | `leading_separator: false` (for the whole source) | `18-constructed/inventory/20-constructed.yml` |
| `key` alone instead of `key_` for an empty value | a dict key with `trailing_separator: false` | `18-constructed/inventory/20-constructed.yml` |
| Group hosts by a condition on their variables | `groups:` with Jinja2 tests (`subset`, `eq`, `search`) | `18-constructed/inventory/20-constructed.yml` |
| Set `ansible_host` from an IP in the guest's config | `compose`, also to name an expression reused by `groups:` | `18-constructed/inventory/20-constructed.yml` |
| Group on a variable from `group_vars/` of a group another source built | a separate `constructed` source with `use_vars_plugins: true` | `18-constructed/inventory/group_vars/proxmox_pool_pool1/` |
| Skip a separate source when only the plugin's own data counts | `keyed_groups`, `groups`, `compose` on the dynamic plugin itself | `18-constructed/direct/` |

## Inventory cache and API load

| Problem | Feature | Where |
|---|---|---|
| Count the API requests one inventory run makes | a mock API that logs each request, emptied before each run | `20-inventory-cache-performance/run.sh`, `mock/server.py` |
| Read guest facts with fewer requests | `want_post_filter_facts: true` instead of `want_facts: true` | `20-inventory-cache-performance/inventory/post-filter-facts.proxmox.yml` |
| Skip the API on the next runs | `cache: true`, `cache_plugin: ansible.builtin.jsonfile`, `cache_connection:` | `20-inventory-cache-performance/inventory/cached.proxmox.yml` |
| Bound how old the cached inventory may get | `cache_timeout:` in seconds (3600 by default, 0 for never) | `20-inventory-cache-performance/inventory/cached.proxmox.yml` |
| Stop waiting for a slow inventory API | an outer limit such as `timeout 2 ansible-inventory …`: the plugin has no timeout option | `20-inventory-cache-performance/run.sh` |

## Hosts created during the run

| Problem | Feature | Where |
|---|---|---|
| Configure VMs in the same run that creates them | `ansible.builtin.add_host` in the provisioning play, a play on the new group after it | `21-add-host/site.yml` |
| Give an added host groups and variables | `groups:` and any other key of `add_host` (`ansible_host`, …) | `21-add-host/provision.yml` |
| Give a group created by `add_host` its variables | `group_vars/<group>/` in the inventory: it applies to the added hosts | `21-add-host/inventory/group_vars/web/` |
| Add one host per host of the play | `add_host` with a `loop`, over `groups['<group>']` | `21-add-host/pitfalls/once-per-play/add.yml` |

## Groups built during a run

| To… | Use | Where |
|---|---|---|
| Put hosts in a group named after a fact, during the play | `group_by: key: os_{{ ansible_facts.os_family }}` | `22-group-by/group-by.yml` |
| Nest the groups group_by builds | `parents:` on `group_by` | `22-group-by/group-by.yml` |
| Give a dynamic group its variables | `group_vars/<group>/` in the inventory; they apply from the next task | `22-group-by/inventory/group_vars/` |
| Keep fact values with spaces or dashes out of group names | `regex_replace('\\W', '_')` on the value | `22-group-by/group-by.yml` |
| Have the same groups at parse time, usable with `--limit` | constructed's `keyed_groups` over cached facts | `22-group-by/keyed/constructed.yml` |

## Writing an inventory plugin

| Problem | Feature | Where |
|---|---|---|
| See which inventory plugins are already installed before writing one | `ansible-doc -t inventory -l` | `23-writing-an-inventory-plugin/run.sh` |
| Read an HTTP/JSON source without writing a plugin | an inventory script, then `ansible.builtin.constructed` in the same inventory directory | `23-writing-an-inventory-plugin/nocode/inventory/` |
| Ship an inventory plugin so `ansible-inventory` and playbooks both find it | a collection (`galaxy.yml`, `plugins/inventory/`), `collections_path` | `23-writing-an-inventory-plugin/collections/ansible_collections/example/cmdb/` |
| Give a plugin `compose`, `groups` and `keyed_groups` | `Constructable` and the `ansible.builtin.constructed` fragment | `23-writing-an-inventory-plugin/collections/ansible_collections/example/cmdb/plugins/inventory/cmdb.py` |
| Take a plugin option from the environment | `env:` under the option in `DOCUMENTATION` | `23-writing-an-inventory-plugin/pitfalls/env-only.cmdb.yml` |
| Report a source error clearly | raise `AnsibleParserError` with the URL and the cause | `23-writing-an-inventory-plugin/collections/ansible_collections/example/cmdb/plugins/inventory/cmdb.py` |
| Fail on an undefined variable in `keyed_groups` | `strict: true` | `23-writing-an-inventory-plugin/pitfalls/rack-strict.cmdb.yml` |
| Read a plugin's options and their environment variables | `ansible-doc -t inventory <fqcn> --json` | `23-writing-an-inventory-plugin/run.sh` |

## Inventory in AWX and AAP

| Problem | Feature | Where |
|---|---|---|
| Use an inventory kept in a repository in AAP | an inventory source from a project, its `source_path` passed to `ansible-inventory -i` | `24-inventory-in-aap/project/inventory/` |
| See what an inventory update stores: group variables on groups, `all`'s as inventory variables | `ansible-inventory --list --export` | `24-inventory-in-aap/run.sh` |
| Reproduce an AAP constructed inventory locally | `-i` each input, then `-i` the `constructed` `source_vars`, then `--limit` | `24-inventory-in-aap/constructed/` |
| Replace a smart inventory's `host_filter` | a pattern or `--limit` on a group, or a `groups` condition in a constructed inventory | `24-inventory-in-aap/run.sh` |
| Fail an inventory build when a limit matches nothing | `ANSIBLE_HOST_PATTERN_MISMATCH=error`, as AWX sets | `24-inventory-in-aap/run.sh` |

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
- A play's `vars:` beat `group_vars`: the inventory says 300, the host gets
  the play's 200 (`08-where-variables-live/messy/`).
- Settings in a playbook or on the command line are invisible to
  `ansible-inventory --host` (`08-where-variables-live/messy/`).
- `group_vars/` beside the playbook beats the inventory's `group_vars/`, and
  `ansible-inventory` doesn't show it without `--playbook-dir`; a role's own
  `group_vars/` is never read (`08-where-variables-live/adjacent/`).
- A role's `vars/main.yml` beats every inventory variable; only `-e` overrides
  it (`08-where-variables-live/roles/pgconf_constants/`).
- `ansible_group_priority` doesn't beat a deeper group: groups sort by depth
  first (`09-inventory-precedence/priority/across-depths/`,
  `conflict/priority-only/`).
- A dict set at two inventory levels is replaced, not merged
  (`09-inventory-precedence/levels/`).
- Without aliases, a secret's variable name exists only inside the encrypted
  file: `grep` can't find it (`10-secrets-in-the-inventory/no-alias/`).
- `ansible-inventory --host` with the vault password prints an encrypted
  file's secrets in clear; inline `!vault` values stay encrypted
  (`10-secrets-in-the-inventory/`).
- Changing one value in an encrypted file, or rekeying it, rewrites every line
  but the header in `git diff` (`10-secrets-in-the-inventory/run.sh`).
- A missing `--vault-id` password fails the whole run unless `--limit` keeps to
  hosts whose files can be decrypted (`10-secrets-in-the-inventory/vault-ids/`).
- A file without an extension, such as `README`, is parsed as YAML, and the
  error doesn't name it (`02-inventory-directory/pitfalls/readme-without-extension/`).
- In one inventory holding both environments, `hosts: app` runs on prod and
  staging (`05-environments/run.sh`).
- Groups at the same depth merge by name: `prod` beats `app`, but `web`
  beats `prod` (`05-environments/precedence/web-after-prod/`).
- An environment group's variables reach all its hosts: `db1` gets
  `app_log_level` from `prod` (`05-environments/single/`).
- `ansible_group_priority` in `group_vars/` is ignored, and shows up as an
  ordinary variable (`05-environments/precedence/priority-in-group-vars/`).
- A misspelled `--limit` only warns about the pattern, then fails with
  *no hosts to target* (`05-environments/run.sh`).
- `ansible-inventory --graph` and `--host` ignore `--limit`; `--list` obeys
  it, and keeps an emptied group in its parent's `children` while dropping
  the group's own entry (`06-ansible-inventory/`).
- `--list --yaml` prints a host's variables under the first group it
  appears in, and `{}` under the others (`06-ansible-inventory/`).
- `ansible-inventory` shows variables unrendered, such as
  `"{{ ansible_playbook_python }}"` (`06-ansible-inventory/`).
- The implicit localhost answers `--host localhost` but is absent from
  `--list` and `--graph` (`06-ansible-inventory/`).
- `group_vars/` beside a playbook reach every play's hosts, but
  `ansible-inventory` shows them only with `--playbook-dir`
  (`06-ansible-inventory/playbooks/`).
- `--toml` fails without the `tomli-w` Python library, which ansible-core
  doesn't install (`06-ansible-inventory/`).
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
- Pattern operators apply by type, not left to right: unions, then
  intersections, then exclusions, so `prod:&app:db` means `(prod or db) and
  app` (`11-host-patterns/run.sh`).
- `strict: true` stops a constructed source at the first host without the
  key: four warnings, one per inventory plugin Ansible tries and an *Unable to
  parse*, yet the groups built before that host stay
  (`11-host-patterns/pitfalls/strict/`).
- Without `use_vars_plugins: true`, `constructed` doesn't see `group_vars/`
  (`11-host-patterns/inventory/30-constructed.yml`).
- `--limit` applies to every play: a play whose hosts it excludes prints
  *skipping: no hosts matched* and the next play runs (`12-limit-in-practice/run.sh`).
- With `--limit`, hosts outside it keep their inventory variables and stay in
  `groups`, but their facts are missing (`12-limit-in-practice/facts.yml`).
- `run_once` runs once per `serial` batch, not once per play
  (`12-limit-in-practice/site.yml`).
- A `--limit` that matches nothing fails with exit 1; a typo in one of its
  hosts, or a play's `hosts:` that matches nothing, only warns
  (`12-limit-in-practice/run.sh`).
- A play looping over a list of hosts in a variable runs one host after
  another, and `--limit <host>` skips it: only `--limit <manager>` runs it,
  on every host in the list (`13-inventory-is-the-loop/run.sh`).
- A list key that's undefined for a host is skipped without a word under
  `strict: false`; an empty item in it gives a group named `tag_` without
  `default_value` (`18-constructed/variants/defaults.yml`).
- With an empty prefix, keyed groups start with `_` (`_os_debian`) unless
  `leading_separator: false` (`18-constructed/variants/defaults.yml`).
- The same `keyed_groups` on the proxmox plugin can't see `group_vars/`:
  `owner_team_a` is missing, although the host gets `owner` (`18-constructed/direct/`).
- `ansible-inventory --list` prints the plugin's values, and values composed
  from them, as `{"__ansible_unsafe": …}`; `--host` prints plain strings
  (`18-constructed/run.sh`).
- A play on hosts that don't exist yet must set `gather_facts: false`, or
  every host is unreachable (`13-inventory-is-the-loop/pitfalls/`).
- A static inventory copied from a CMDB keeps a retired host and an old
  owner once the CMDB changes (`15-single-source-of-truth/static/`).
- With `cache: true`, the plugin keeps returning the old hosts after the
  source changes, until `--flush-cache` or `cache_timeout` (`15-single-source-of-truth/run.sh`).
- An unreachable source, or a plugin config with `auto` left out of
  `enable_plugins`, gives warnings and an empty inventory, and
  `ansible-inventory` exits 0 (`15-single-source-of-truth/run.sh`).
- A misspelled name in `enable_plugins` only warns: *Failed to load inventory
  plugin, skipping* (`15-single-source-of-truth/run.sh`).
- A plugin in `inventory_plugins/` beside a playbook is found by
  `ansible-playbook`, but `ansible-inventory` says *specifies unknown plugin*
  without `--playbook-dir` (`15-single-source-of-truth/pitfalls/adjacent/`).
- Strings set by a custom inventory plugin are untrusted: `--list` prints
  them as `{"__ansible_unsafe": …}`, an inventory script's as plain strings
  (`15-single-source-of-truth/run.sh`).
- An inventory cache in the default `memory` plugin lasts one run: the next
  run calls the source again (`19-inventory-cache-stale-data/run.sh`).
- An expired cache is not a fallback: with the source down, the plugin
  returns no hosts and `ansible-inventory` exits 0, although the cache file
  is still there (`19-inventory-cache-stale-data/run.sh`).
- The cache key is the plugin name and the configuration file's absolute
  path: a copy of the file elsewhere misses the cache, `./` or an absolute
  path doesn't (`19-inventory-cache-stale-data/run.sh`).
- A play on a cached inventory runs on a host the source has removed
  (`19-inventory-cache-stale-data/deploy.yml`).
- With `cache: true` and no `cache_plugin`, the inventory cache takes the
  fact cache settings (`ANSIBLE_CACHE_PLUGIN`, `fact_caching`): set for facts,
  they make the inventory persistent and stale too (`19-inventory-cache-stale-data/run.sh`).
- `--flush-cache` clears the facts of the hosts in the refreshed inventory
  only: a removed host's cached facts stay (`19-inventory-cache-stale-data/run.sh`).
- Inventory files in a directory sort as text too: `9-override.yml` loads
  after `10-hosts.yml` and wins (`14-several-inventories/name-order/`).
- With `-i dir1 -i dir2`, each directory's `group_vars/` applies to the hosts
  of both: `group_vars/all/` of the last one sets `env` for every host
  (`14-several-inventories/environments/`).
- A host defined in two sources keeps the first source as `inventory_file`
  (`14-several-inventories/run.sh`).
- A script without the execute bit is handed to the `ini` plugin, which
  fails; Ansible warns and loads the rest (`14-several-inventories/pitfalls/not-executable/`).
- A `README` with no extension in an inventory directory only warns and the
  other sources load, unlike in `group_vars/`
  (`14-several-inventories/pitfalls/readme/`).
- The Foreman plugin's Hosts API makes no location or organization groups,
  only host groups; the Reports API makes both (`16-foreman-inventory/run.sh`).
- Without a cache, the Foreman plugin asks for each host separately, twice
  when both `want_params` and `want_hostcollections` are set, and facts take
  two requests per host: 13 requests for 3 hosts (`16-foreman-inventory/run.sh`).
- `--limit` doesn't reduce what the Foreman plugin fetches: it reads every
  host, then the limit applies (`16-foreman-inventory/run.sh`).
- A host collection named *Web servers* gives `foreman_hostcollection_webservers`
  through the Hosts API and `foreman_hostcollection_web_servers` through the
  Reports API (`16-foreman-inventory/run.sh`).
- The default Reports API against a Foreman without `foreman_ansible` only
  warns: `ansible-inventory` exits 0 with no hosts
  (`16-foreman-inventory/pitfalls/no-foreman-ansible.foreman.yml`).
- A Foreman source whose name doesn't end in `foreman.yml` or `foreman.yaml`
  is skipped with warnings, and the inventory is empty
  (`16-foreman-inventory/pitfalls/foreman-inventory.yml`).
- One guest with an empty name makes the Proxmox source fail as a whole:
  no host at all, warnings, exit code 0 (`17-proxmox-inventory/pitfalls/unnamed.proxmox.yml`).
- `plugin: community.general.proxmox` is redirected to community.proxmox
  with a deprecation warning, then refused by the plugin's own `choices`:
  empty inventory, exit code 0 (`17-proxmox-inventory/pitfalls/redirect.proxmox.yml`).
- Two guests with the same name make one host: the variables of the last
  one read, the groups of both (`17-proxmox-inventory/run.sh`).
- A filter on a fact that only `want_facts` provides errors for every guest
  and keeps them all, with a warning each (`17-proxmox-inventory/pitfalls/tags-parsed.proxmox.yml`).
- `cache: true` alone uses the `memory` cache plugin: the cache dies with
  the process, and every run makes all its requests again
  (`20-inventory-cache-performance/pitfalls/memory-cache.proxmox.yml`).
- `want_facts` reads the configuration of every guest, filtered out or not:
  407 requests against 207 with `want_post_filter_facts`, for the same 60
  hosts (`20-inventory-cache-performance/run.sh`).
- With a password, the Proxmox plugin asks for a ticket even when its cache
  is warm: with the API down the source fails and the inventory is empty,
  exit 0; with an API token it reads the cache (`20-inventory-cache-performance/run.sh`).
- The Proxmox plugin sets no timeout on its requests: a slow API makes
  `ansible-inventory` wait as long as it takes (`20-inventory-cache-performance/pitfalls/slow-api.proxmox.yml`).
- `add_host` without a loop runs once per play, on the first host, not once
  per host (`21-add-host/pitfalls/once-per-play/`).
- A host added by `add_host` joins `ansible_play_hosts` of the play that
  added it, though the play's tasks don't run on it
  (`21-add-host/pitfalls/once-per-play/`).
- Hosts added by `add_host` stay out of a run with `--limit <manager>`; a
  `--limit` naming them warns *Could not match* but still lets them in, and a
  `--limit` naming only them fails with exit 1 (`21-add-host/run.sh`).
- `add_host` leaves nothing behind: `ansible-inventory` and the next run
  don't see the added hosts (`21-add-host/run.sh`).
- `group_by` keeps a space in the group name in ansible-core 2.21.4, though
  its docs and its result say dash: the group can't be targeted
  (`22-group-by/pitfalls/spaces.yml`).
- A host whose `group_by` key fails is in no group and leaves the run
  (`22-group-by/pitfalls/no-default.yml`).
- `--limit` can't name a group `group_by` builds, and with `--limit` only the
  limited hosts are grouped; the groups are gone after the run
  (`22-group-by/run.sh`).
- A required plugin option set to an empty string passes Ansible's
  `required` check: the plugin has to reject it itself
  (`23-writing-an-inventory-plugin/run.sh`).
- `keyed_groups` on a missing field silently makes no group unless
  `strict: true` (`23-writing-an-inventory-plugin/pitfalls/rack.cmdb.yml`).
- In a constructed inventory, each input's `all` variables apply to every
  host: the last input's `site` wins for the hosts of both
  (`24-inventory-in-aap/run.sh`).
- With AWX's `ANSIBLE_INVENTORY_UNPARSED_FAILED=True`, a constructed source
  that fails with `strict: true` only warns while the inputs parse; the run
  fails through the limit, or with `ANSIBLE_INVENTORY_ANY_UNPARSED_IS_FAILED`
  (`24-inventory-in-aap/pitfalls/`).

## Testing patterns worth reusing

| To… | How | Where |
|---|---|---|
| Test an inventory without any server | every host with `ansible_connection: local` | `01-…`, `02-…` |
| Test SSH and container connections in CI | an sshd container on `127.0.0.1:2222`, a key pair generated per run | `04-connection-variables/run.sh`, `containers/Containerfile` |
| Keep machine-specific names out of `expected.txt` | compare a fact with the controller's own value, print a fixed label | `04-connection-variables/whoami.yml` |
| Run vault examples anywhere, CI included | test-only vault passwords committed and named as such, dummy data only | `10-secrets-in-the-inventory/vault-pass/` |
| Show a wrong layout next to the right one | a small inventory per pitfall, printed with `ansible-inventory --host` | `02-inventory-directory/pitfalls/` |
| Test drift against real package databases | one container per version, built from images pinned by digest | `07-facts-or-variables/containers/` |
| Overlay a wrong inventory on the right one | a second `-i` source that adds one variable | `07-facts-or-variables/run.sh`, `pitfalls/` |
| Record a command that's expected to fail, and keep going | `if … ; then … ; else` with the exit code and stderr in the output | `02-inventory-directory/run.sh` |
| Show which hosts a pattern reached, with a variable each got | one `run_once` task on localhost looping over `ansible_play_hosts_all` | `05-environments/app.yml` |
| Print a command, its output, and its exit code when it fails | a shell function around `ansible-inventory` | `06-ansible-inventory/run.sh` |
| Keep task output in the same order on every run | `forks = 1` in the example's `ansible.cfg` | `12-limit-in-practice/ansible.cfg` |
| Test cache expiry without flaky timings | a 5-second `cache_timeout`, `sleep 6`, outcomes printed rather than times | `19-inventory-cache-stale-data/run.sh` |
| Test an inventory plugin or script without a real API | `python3 -m http.server` serving a JSON fixture, started and stopped by `run.sh` | `15-single-source-of-truth/run.sh` |
| Test a dynamic inventory plugin without its server | a small Python mock of the API, started and stopped by `run.sh` | `18-constructed/mock/pve.py` |
| Show parallelism without flaky timings | a one-second `wait_for` per host, durations printed as a range | `13-inventory-is-the-loop/run.sh` |
| Print the order Ansible parsed sources in, without absolute paths | `-vvv` output filtered with `sed` on *Parsed … inventory source* | `14-several-inventories/run.sh` |
| Test an API-backed inventory plugin without the service | a Python server answering recorded JSON, logging each request; `run.sh` starts and stops it | `16-foreman-inventory/mock/foreman.py`, `run.sh` |
| Test an inventory plugin without its server | a mock of the API in Python, serving recorded responses and logging each request | `17-proxmox-inventory/mock/` |
| Show what a cache saves without flaky timings | a fixed latency per request in the mock; wall time checked as a lower bound and a ratio | `20-inventory-cache-performance/run.sh` |
| Test a large inventory without a large fixture in Git | a script generating the mock's responses at each run | `20-inventory-cache-performance/mock/generate.py` |
| Expire a cache without waiting | `touch -d '2 hours ago'` on the cache file | `20-inventory-cache-performance/run.sh` |
| Show which hosts each play reached | each play writes one file per host in `out/`, `run.sh` lists them | `21-add-host/run.sh` |
| Give local hosts different facts | recorded facts copied into a `jsonfile` fact cache with `fact_caching_timeout = 0` | `22-group-by/facts/`, `ansible.cfg` |
| Unit-test an inventory plugin without a server | pytest, `unittest.mock.patch` on `open_url`, `inventory_loader.get()` with a `conftest.py` that sets up the collection loader | `23-writing-an-inventory-plugin/collections/ansible_collections/example/cmdb/tests/unit/` |
| Test a token-protected API | a mock that answers 401 without the test-only token and logs whether each request had it | `23-writing-an-inventory-plugin/mock/cmdb.py` |
| Run what a controller runs, without the controller | the same `ansible-inventory` arguments and environment variables, read from its source | `24-inventory-in-aap/run.sh` |
