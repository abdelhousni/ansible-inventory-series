#!/usr/bin/env python3
"""A script inventory: prints the staging hosts as JSON when called with --list.

It stands in for a CMDB or a cloud API. Ansible runs it because it is
executable; the same file without the execute bit is skipped.
"""
import json
import sys

INVENTORY = {
    "app": {"hosts": ["stg-app1"]},
    "db": {"hosts": ["stg-db1"]},
    "staging": {"hosts": ["stg-app1", "stg-db1"]},
    "_meta": {"hostvars": {}},
}

if len(sys.argv) > 1 and sys.argv[1] == "--list":
    print(json.dumps(INVENTORY))
else:
    print(json.dumps({}))
