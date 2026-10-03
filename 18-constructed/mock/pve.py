#!/usr/bin/env python3
"""A minimal, read-only mock of the Proxmox VE API for the examples.

It answers only the GET endpoints community.proxmox's inventory plugin calls
with token authentication and want_facts: true. Guests are modelled on the
data-shaping series' part 12, with tags and static IPs added.
Usage: pve.py PORT
"""
import json
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

NODES = ["pve", "pve2"]

# vmid: node, type, name, status, tags (Proxmox stores them ;-separated), config
GUESTS = {
    100: ("pve", "qemu", "pxe.home.arpa", "running", "infra;dhcp",
          {"ostype": "l26", "ipconfig0": "ip=10.0.10.100/24,gw=10.0.10.1"}),
    101: ("pve2", "qemu", "test1", "stopped", "web;staging",
          {"ipconfig0": "ip=10.0.10.101/24,gw=10.0.10.1"}),
    102: ("pve", "lxc", "test-lxc.home.arpa", "running", "web;prod",
          {"ostype": "debian", "net0": "name=eth0,bridge=vmbr0,ip=10.0.10.102/24,gw=10.0.10.1"}),
    103: ("pve2", "lxc", "test1-lxc.home.arpa", "stopped", "db;prod",
          {"ostype": "debian", "net0": "name=eth0,bridge=vmbr0,ip=10.0.10.103/24,gw=10.0.10.1"}),
    104: ("pve2", "lxc", "test2-lxc.home.arpa", "stopped", "",
          {"ostype": "alpine", "net0": "name=eth0,bridge=vmbr0,ip=10.0.10.104/24,gw=10.0.10.1"}),
}
POOLS = {"pool1": [101, 103]}


def guest_summary(vmid):
    node, vtype, name, status, tags, _config = GUESTS[vmid]
    item = {"vmid": vmid, "name": name, "status": status, "type": vtype}
    if tags:
        item["tags"] = tags
    return item


def route(parts):
    """Returns the data for an API path split on '/', or None for a 404."""
    if parts == ["nodes"]:
        return [{"node": n, "status": "online", "type": "node"} for n in NODES]
    if parts == ["pools"]:
        return [{"poolid": p} for p in POOLS]
    if len(parts) == 2 and parts[0] == "pools" and parts[1] in POOLS:
        return {"poolid": parts[1], "members": [guest_summary(v) for v in POOLS[parts[1]]]}
    if len(parts) >= 3 and parts[0] == "nodes" and parts[1] in NODES:
        node, vtype = parts[1], parts[2]
        if len(parts) == 3:
            return [guest_summary(v) for v, g in sorted(GUESTS.items()) if g[0] == node and g[1] == vtype]
        vmid = int(parts[3]) if parts[3].isdigit() else None
        if vmid not in GUESTS or GUESTS[vmid][:2] != (node, vtype):
            return None
        _node, _type, name, status, tags, config = GUESTS[vmid]
        tail = parts[4:]
        if tail == ["status", "current"]:
            current = {"status": status}
            if vtype == "qemu":
                current["qmpstatus"] = status
            return current
        if tail == ["config"]:
            result = {"hostname" if vtype == "lxc" else "name": name, **config}
            if tags:
                result["tags"] = tags
            return result
        if tail == ["snapshot"]:
            return [{"name": "current"}]
        if tail == ["interfaces"]:
            return []
    return None


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):  # noqa: N802
        prefix = "/api2/json/"
        if not self.headers.get("Authorization", "").startswith("PVEAPIToken="):
            self.reply(401, None)
            return
        data = route(self.path[len(prefix):].split("/")) if self.path.startswith(prefix) else None
        self.reply(404 if data is None else 200, data)

    def reply(self, code, data):
        body = json.dumps({"data": data}).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *args):
        pass


if __name__ == "__main__":
    ThreadingHTTPServer(("127.0.0.1", int(sys.argv[1])), Handler).serve_forever()
