# 24: inventory in AAP: sources, smart and constructed inventories

Example for [item 24](https://til.housni.eu/ansible/inventory-in-aap-sources-smart-constructed.html).
No AWX or Ansible Automation Platform (AAP) runs here: `run.sh` runs, with
ansible-core alone, the `ansible-inventory` commands that AWX builds for an
inventory update (`build_args` in `awx/main/tasks/jobs.py`), with the
environment AWX sets for it (`STANDARD_INVENTORY_UPDATE_ENV` in
`awx/main/constants.py`).

| Path | What it shows |
|---|---|
| `project/inventory/` | an inventory directory as it would sit in a project's repository: the `source_path` of an inventory source from a project |
| `constructed/east.ini`, `constructed/west.ini` | the two input inventories of the AWX docs' constructed inventory demo, each with an `[all:vars]` added |
| `constructed/constructed.yml` | the demo's `source_vars`, with the plugin's full name |
| `pitfalls/typo-strict-true.yml`, `pitfalls/typo-strict-false.yml` | the same `source_vars` with a typo in a variable name, `strict: true` and `false` |

The input inventories keep their variables on the host lines, as the AWX
docs write them, rather than in `host_vars/`.

`run.sh` shows:

1. what an inventory update from a project stores: `--export` keeps group
   variables on their groups, and `all`'s become the inventory's variables;
2. a smart inventory's `host_filter` on a group, as a pattern;
3. the demo's constructed inventory: host2 and host6, and the inputs'
   `all` variables, where the last input wins for every host;
4. a typo in the `source_vars`: the update fails only through the limit,
   unless `ANSIBLE_INVENTORY_ANY_UNPARSED_IS_FAILED` is set;
5. a limit that matches nothing, fatal in AWX's environment only.

```sh
./run.sh
```

It needs jq. Compare with [`expected.txt`](expected.txt).
