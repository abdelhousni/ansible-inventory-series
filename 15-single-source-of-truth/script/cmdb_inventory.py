#!/usr/bin/env python3
"""Inventory script: reads the CMDB and prints the inventory as JSON.

Ansible runs it with --list; --host is there for the protocol, but --list
returns _meta.hostvars, so Ansible never calls it.
"""
import json
import sys
import urllib.request

CMDB_URL = "http://127.0.0.1:18150/hosts.json"


def inventory():
    try:
        with urllib.request.urlopen(CMDB_URL, timeout=5) as response:
            servers = json.load(response)["servers"]
    except OSError as e:
        sys.exit(f"cannot read the CMDB at {CMDB_URL}: {e}")
    result = {"_meta": {"hostvars": {}}}
    for server in servers:
        result.setdefault(server["role"], {"hosts": []})["hosts"].append(server["name"])
        result["_meta"]["hostvars"][server["name"]] = {"cmdb_owner": server["owner"]}
    return result


if __name__ == "__main__":
    if sys.argv[1:] == ["--list"]:
        print(json.dumps(inventory()))
    elif len(sys.argv) == 3 and sys.argv[1] == "--host":
        print(json.dumps(inventory()["_meta"]["hostvars"].get(sys.argv[2], {})))
    else:
        sys.exit("usage: cmdb_inventory.py --list | --host <name>")
