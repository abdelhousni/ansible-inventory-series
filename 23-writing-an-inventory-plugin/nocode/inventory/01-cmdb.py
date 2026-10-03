#!/usr/bin/env python3
"""Inventory script: reads the CMDB and prints the inventory as JSON.

The URL and the token come from CMDB_URL and CMDB_TOKEN. Each server goes in
a group named after its role; its other fields become cmdb_* variables.
"""
import json
import os
import sys
import urllib.request


def inventory():
    url = os.environ["CMDB_URL"]
    request = urllib.request.Request(url, headers={"Authorization": f"Bearer {os.environ['CMDB_TOKEN']}"})
    try:
        with urllib.request.urlopen(request, timeout=5) as response:
            servers = json.load(response)["servers"]
    except OSError as e:
        sys.exit(f"cannot read the CMDB at {url}: {e}")
    result = {"_meta": {"hostvars": {}}}
    for server in servers:
        result.setdefault(server["role"], {"hosts": []})["hosts"].append(server["name"])
        result["_meta"]["hostvars"][server["name"]] = {
            f"cmdb_{key}": value for key, value in server.items() if key != "name"
        }
    return result


if __name__ == "__main__":
    if sys.argv[1:] == ["--list"]:
        print(json.dumps(inventory()))
    elif len(sys.argv) == 3 and sys.argv[1] == "--host":
        print(json.dumps(inventory()["_meta"]["hostvars"].get(sys.argv[2], {})))
    else:
        sys.exit("usage: 01-cmdb.py --list | --host <name>")
