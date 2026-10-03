# 21: add_host, provision then configure in one run

Example for [item 21](https://til.housni.eu/ansible/inventory-add-host-provision-then-configure.html).
It continues [item 13](../13-inventory-is-the-loop/)'s fake manager: here the
VMs aren't in the inventory before the run. A first play creates them on
`manager1` and adds them to the in-memory inventory with
`ansible.builtin.add_host`; the next play configures them.

| Path | What it shows |
|---|---|
| `inventory/hosts.yml` | only the manager: the VMs don't exist yet |
| `inventory/host_vars/manager1/` | what to order, a prefix, a count and a size, not a list of hosts |
| `inventory/group_vars/all/` | the local connection, which the added hosts get too |
| `inventory/group_vars/web/` | `web_port`, for the group that only `add_host` creates |
| `provision.yml` | creates each VM (a file in `out/manager/`), then `add_host` in a loop, into groups `web` and `new_vms` with `ansible_host`, `vm_cpus`, `vm_manager` |
| `configure.yml` | a play on `web` writing what each VM received to `out/web/` |
| `site.yml` | both, in one run |
| `pitfalls/once-per-play/` | two managers: `add_host` without a loop adds one host, not two |

`run.sh` shows the inventory before and after the run, runs `site.yml`,
then `configure.yml` alone, `site.yml` with three `--limit` values, and the
once-per-play pitfall. The VMs' addresses are from 192.0.2.0/24, reserved
for documentation; every host connects locally.

```sh
./run.sh
```

Compare with [`expected.txt`](expected.txt).
