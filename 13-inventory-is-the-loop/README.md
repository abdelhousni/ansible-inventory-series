# 13: let the inventory be the loop

Example for [item 13](https://til.housni.eu/ansible/inventory-is-the-loop-delegate-to.html),
after the Red Hat CoP good practice *Rely on your inventory to loop over
hosts, don't create lists of hosts*.

A fake manager, `manager1`, stands in for a hypervisor or Foreman: creating a
VM takes a second (`wait_for: timeout: 1`), then writes
`out/manager/<vm>.txt` with the VM's size.

| Path | What it shows |
|---|---|
| `bad/` | the VMs listed with their sizes in `host_vars/manager1/`, besides the inventory's groups |
| `not-so-bad/` | only the VM names in that list; each VM's size in `group_vars/` and `host_vars/` |
| `good/` | no list: the VMs are hosts, sized by `group_vars/app/`, `group_vars/db/` and `host_vars/db1/` |
| `provision-bad.yml`, `provision-not-so-bad.yml` | a play on the manager looping over its list, through `tasks/create_vm.yml` |
| `provision-good.yml` | a play on the VMs, each task with `delegate_to: "{{ vm_manager }}"` |
| `pitfalls/gather-facts.yml` | the good play with fact gathering left on |

In `good/`, the VMs connect over SSH to `127.0.0.1:1`, where nothing
listens, as a VM that doesn't exist yet would: the delegated tasks connect
to the manager instead, locally.

`run.sh` shows where each layout writes a VM's name and size, provisions the
five VMs with each, runs `--limit db1` against the bad and good layouts, and
shows gathering facts fail on VMs that don't exist yet. It prints durations
as a range, 5 s or more, or under 5 s: five sequential one-second calls can't
take less.

```sh
./run.sh
```

It needs the OpenSSH client. Compare with [`expected.txt`](expected.txt).
