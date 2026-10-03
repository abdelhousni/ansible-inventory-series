#!/usr/bin/env python3
"""Writes a larger api.json for mock/server.py: two nodes, GUESTS guests.

    mock/generate.py GUESTS [SLOW_NODES_S] > api.json

Guests get VMIDs from 200: an even VMID is a QEMU VM, an odd one an LXC
container, on pve or pve2 by pair, running when the VMID is a multiple of
three, tagged web for the first half and db for the second. Each guest has
the status, configuration and snapshots the plugin reads with want_facts,
plus agent or container interfaces when it runs. SLOW_NODES_S, when given,
makes /nodes answer that many seconds late.
"""
import json
import sys


def guest(api, vmid, half):
    vmtype = "qemu" if vmid % 2 == 0 else "lxc"
    node = "pve" if vmid // 2 % 2 == 0 else "pve2"
    status = "running" if vmid % 3 == 0 else "stopped"
    name = f"{vmtype}-{vmid}.home.arpa"
    tags = "web" if vmid < 200 + half else "db"
    ip = f"10.0.{vmid // 256}.{vmid % 256}"
    base = f"/nodes/{node}/{vmtype}/{vmid}"
    api.setdefault(f"/nodes/{node}/{vmtype}", []).append(
        {"vmid": vmid, "name": name, "status": status, "tags": tags}
    )
    api[f"{base}/status/current"] = {"status": status, "vmid": vmid, "qmpstatus": status}
    api[f"{base}/snapshot"] = [{"name": "current", "description": "You are here!"}]
    if vmtype == "qemu":
        api[f"{base}/config"] = {
            "name": name, "cores": 1, "memory": "1024", "tags": tags,
            "ipconfig0": f"ip={ip}/16", "agent": "1" if status == "running" else "0",
        }
        if status == "running":
            api[f"{base}/agent/network-get-interfaces"] = {"result": [
                {"name": "eth0", "ip-addresses": [{"ip-address": ip, "prefix": 16}]},
            ]}
    else:
        api[f"{base}/config"] = {
            "hostname": name, "cores": 1, "memory": 512, "tags": tags,
            "net0": f"name=eth0,bridge=vmbr0,ip={ip}/16",
        }
        if status == "running":
            api[f"{base}/interfaces"] = [{"name": "eth0", "hwaddr": "bc:24:11:00:00:00", "inet": f"{ip}/16"}]


def main():
    guests = int(sys.argv[1])
    nodes = [{"node": n, "status": "online", "type": "node", "id": f"node/{n}"} for n in ("pve", "pve2")]
    api = {"/nodes": nodes, "/pools": [], "/nodes/pve/qemu": [], "/nodes/pve/lxc": [],
           "/nodes/pve2/qemu": [], "/nodes/pve2/lxc": []}
    if len(sys.argv) > 2:
        api["/nodes"] = {"_delay": float(sys.argv[2]), "_data": nodes}
    for vmid in range(200, 200 + guests):
        guest(api, vmid, guests // 2)
    json.dump(api, sys.stdout, indent=1, sort_keys=True)


if __name__ == "__main__":
    main()
