#!/usr/bin/env bash
# Shows how an inventory cache goes stale: the memory and jsonfile cache
# plugins, cache_timeout, two sources sharing a cache directory, a play that
# targets a host the CMDB no longer has, and how the fact cache settings and
# --flush-cache reach the inventory cache. CI compares this output with
# expected.txt.
set -euo pipefail
cd "$(dirname "$0")"
rm -rf out
mkdir -p out/cmdb
out=$PWD/out

# The mock CMDB, as in item 15: Python's own web server, serving out/cmdb/.
cmdb_pid=
start_cmdb() {
  python3 -m http.server --bind 127.0.0.1 --directory out/cmdb 18190 >out/cmdb.log 2>&1 &
  cmdb_pid=$!
  python3 - <<'PY'
import time, urllib.request
for _ in range(50):
    try:
        urllib.request.urlopen("http://127.0.0.1:18190/hosts.json", timeout=1)
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

# Prints the exit code of ansible-inventory --list and its hosts, sorted.
show() {
  local label=$1 rc=0
  shift
  ansible-inventory --list "$@" >"$out/list.json" 2>"$out/stderr" || rc=$?
  python3 - "$label" "$rc" "$out/list.json" <<'PY'
import json, sys
label, rc, path = sys.argv[1:]
text = open(path).read()
hosts = sorted(json.loads(text)["_meta"]["hostvars"]) if text else []
print(f"  {label}: exit {rc}, {' '.join(hosts) or 'no hosts'}")
PY
}

# Lists the files in a directory, with the cache key's hash replaced.
files() {
  find "$1" -type f -printf '%f\n' | sed 's/k[0-9a-f]\{6\}$/k<hash>/' | sort | xargs
}

echo "== 1. memory or jsonfile: the CMDB changes between two runs"
cp cmdb/v1.json out/cmdb/hosts.json
cp cmdb/dc2.json out/cmdb/dc2.json
start_cmdb
show "memory, CMDB v1" -i sources/memory.cmdb.yml
show "jsonfile, CMDB v1" -i sources/jsonfile.cmdb.yml
cp cmdb/v2.json out/cmdb/hosts.json
show "memory, CMDB v2" -i sources/memory.cmdb.yml
show "jsonfile, CMDB v2" -i sources/jsonfile.cmdb.yml
echo "  out/cache: $(files out/cache)"

echo
echo "== 2. cache_timeout: 5 seconds"
cp cmdb/v1.json out/cmdb/hosts.json
show "CMDB v1, cache filled" -i sources/short.cmdb.yml
cp cmdb/v2.json out/cmdb/hosts.json
show "CMDB v2, at once" -i sources/short.cmdb.yml
sleep 6
show "CMDB v2, 6 seconds later" -i sources/short.cmdb.yml
sleep 6
stop_cmdb
show "CMDB down, cache 6 seconds old" -i sources/short.cmdb.yml
echo "    $(grep -o 'cannot read the CMDB at [^ ]*json' "$out/stderr" | head -1)"
echo "  out/short still holds: $(files out/short)"
start_cmdb

echo
echo "== 3. Two sources, one cache_connection and cache_prefix"
cp cmdb/v1.json out/cmdb/hosts.json
show dc1 -i sources/dc1.cmdb.yml
show dc2 -i sources/dc2.cmdb.yml
echo "  out/shared: $(files out/shared)"
stop_cmdb
show "dc1, CMDB down" -i sources/dc1.cmdb.yml
show "dc2, CMDB down" -i sources/dc2.cmdb.yml
cp sources/dc1.cmdb.yml out/dc1.cmdb.yml
show "a copy of dc1's file, CMDB down" -i out/dc1.cmdb.yml
show "dc1 as ./sources/dc1.cmdb.yml, CMDB down" -i ./sources/dc1.cmdb.yml
show "dc1 by its absolute path, CMDB down" -i "$PWD/sources/dc1.cmdb.yml"
start_cmdb

echo
echo "== 4. app2 is decommissioned, the cache still has it"
rm -rf out/cache
cp cmdb/v1.json out/cmdb/hosts.json
show "CMDB v1, cache filled" -i sources/jsonfile.cmdb.yml
cp cmdb/v2.json out/cmdb/hosts.json
for flags in "" "--flush-cache"; do
  ansible-playbook -i sources/jsonfile.cmdb.yml deploy.yml $flags >out/deploy.out 2>&1
  echo "  ansible-playbook deploy.yml ${flags:-(cache)}: $(grep -o 'deploying to [a-z0-9]*' out/deploy.out | xargs)"
done

echo
echo "== 5. The fact cache settings and the inventory cache"
export ANSIBLE_CACHE_PLUGIN=ansible.builtin.jsonfile ANSIBLE_CACHE_PLUGIN_CONNECTION=out/facts
cp cmdb/v1.json out/cmdb/hosts.json
show "memory.cmdb.yml, fact cache in jsonfile, CMDB v1" -i sources/memory.cmdb.yml
ansible-playbook -i sources/memory.cmdb.yml record-facts.yml >out/record.out 2>&1
echo "  out/facts: $(files out/facts)"
cp cmdb/v2.json out/cmdb/hosts.json
show "memory.cmdb.yml, CMDB v2" -i sources/memory.cmdb.yml
ansible-playbook -i sources/memory.cmdb.yml deploy.yml --flush-cache >out/deploy.out 2>&1
echo "  after ansible-playbook --flush-cache, CMDB v2: $(files out/facts)"
