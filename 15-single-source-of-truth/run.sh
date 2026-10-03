#!/usr/bin/env bash
# Reads the hosts of a mock CMDB three ways: a static inventory copied from it
# by hand, an inventory script, and the example's own inventory plugin. Changes
# the CMDB, shows how Ansible picks a plugin and what enable_plugins changes,
# then stops the CMDB and reads the plugin's cache. CI compares this output
# with expected.txt.
set -euo pipefail
cd "$(dirname "$0")"
rm -rf out
mkdir -p out/cmdb
out=$PWD/out

# The mock CMDB: Python's own web server, serving out/cmdb/hosts.json.
cmdb_pid=
start_cmdb() {
  python3 -m http.server --bind 127.0.0.1 --directory out/cmdb 18150 >out/cmdb.log 2>&1 &
  cmdb_pid=$!
  python3 - <<'PY'
import time, urllib.request
for _ in range(50):
    try:
        urllib.request.urlopen("http://127.0.0.1:18150/hosts.json", timeout=1)
        break
    except OSError:
        time.sleep(0.1)
PY
}
stop_cmdb() {
  if [ -n "$cmdb_pid" ]; then
    kill "$cmdb_pid"
    wait "$cmdb_pid" 2>/dev/null || true
  fi
  cmdb_pid=
}
trap stop_cmdb EXIT

# Prints one line per source: the exit code of ansible-inventory --list, then
# each host with its group and owner. Then the warnings, without paths. Writes
# to $out, so that it runs from any directory.
show() {
  local label=$1 rc=0
  shift
  ansible-inventory --list "$@" >"$out/list.json" 2>"$out/stderr" || rc=$?
  python3 - "$label" "$rc" "$out/list.json" <<'PY'
import json, sys
label, rc, path = sys.argv[1:]
text = open(path).read()
inv = json.loads(text) if text else {"_meta": {"hostvars": {}}}
hostvars = inv["_meta"]["hostvars"]
def owner(host):
    value = hostvars[host]["cmdb_owner"]
    return value["__ansible_unsafe"] if isinstance(value, dict) else value
hosts = [f"{h}({g}, {owner(h)})"
         for g in sorted(inv) if g not in ("_meta", "all", "ungrouped")
         for h in inv[g].get("hosts", [])]
print(f"  {label}: exit {rc}, {' '.join(hosts) or 'no hosts'}")
PY
  grep -h -e '^\[WARNING\]' -e '^\[ERROR\]' "$out/stderr" | sed "s|$PWD/||g; s|^|    |" || true
}

# Prints db1's cmdb_owner as ansible-inventory --list wrote it.
db1_owner() {
  python3 -c 'import json, sys
print(json.dumps(json.load(open(sys.argv[1]))["_meta"]["hostvars"]["db1"]["cmdb_owner"]))' "$1"
}

echo "== 1. The CMDB holds app1, app2, db1: three sources, the same inventory"
cp cmdb/v1.json out/cmdb/hosts.json
start_cmdb
show static -i static/inventory
show script -i script/cmdb_inventory.py
cp out/list.json out/script.json
show plugin -i plugin/hosts.cmdb.yml
echo "  db1's cmdb_owner in --list: script $(db1_owner out/script.json), plugin $(db1_owner out/list.json)"

echo
echo "== 2. The CMDB changes: app2 retired, app3 added, db1 handed to data-team"
cp cmdb/v2.json out/cmdb/hosts.json
show static -i static/inventory
show script -i script/cmdb_inventory.py
show "plugin, from its cache" -i plugin/hosts.cmdb.yml
show "plugin, --flush-cache" -i plugin/hosts.cmdb.yml --flush-cache
show "plugin, cache refreshed" -i plugin/hosts.cmdb.yml

echo
echo "== 3. How Ansible picked the plugin"
ansible-config dump >out/config.txt 2>&1
grep '^INVENTORY_ENABLED' out/config.txt | sed 's/^/  /'
ansible-inventory --list -i plugin/hosts.cmdb.yml -vvv >out/vvv.txt 2>&1
grep -E 'declined parsing|^Using inventory plugin|^Parsed ' out/vvv.txt | sed "s|$PWD/||g; s|^|  |"

echo
echo "== 4. enable_plugins"
ANSIBLE_INVENTORY_ENABLED=host_list,script,yaml,ini,toml show "without auto" -i plugin/hosts.cmdb.yml
ANSIBLE_INVENTORY_ENABLED=cmdb,yaml show "cmdb, yaml" -i plugin/hosts.cmdb.yml
ANSIBLE_INVENTORY_ENABLED=cmbd,auto,yaml show "cmbd (typo), auto, yaml" -i plugin/hosts.cmdb.yml

echo
echo "== 5. A plugin in inventory_plugins/ beside a playbook"
(
  cd pitfalls/adjacent
  show ansible-inventory -i hosts.cmdb.yml
  show "ansible-inventory --playbook-dir ." -i hosts.cmdb.yml --playbook-dir .
  rc=0
  ansible-playbook -i hosts.cmdb.yml owners.yml >"$out/adjacent.out" 2>&1 || rc=$?
  echo "  ansible-playbook: exit $rc"
  grep -o '"msg": "[^"]*"' "$out/adjacent.out" | sed 's/^/    /'
)

echo
echo "== 6. The CMDB is down"
stop_cmdb
show "plugin, from its cache" -i plugin/hosts.cmdb.yml
show script -i script/cmdb_inventory.py
show "plugin, --flush-cache" -i plugin/hosts.cmdb.yml --flush-cache
ANSIBLE_INVENTORY_ANY_UNPARSED_IS_FAILED=true show "script, any_unparsed_is_failed" -i script/cmdb_inventory.py
echo "  cache files: $(find out/cache -type f | sed 's/k[0-9a-f]\{6\}$/k<hash>/' | sort | xargs)"
