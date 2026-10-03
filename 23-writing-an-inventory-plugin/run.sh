#!/usr/bin/env bash
# Looks for an existing way to read the example CMDB before writing code: the
# inventory plugins ansible-core ships, then an inventory script with the
# constructed plugin. Then runs the example's own inventory plugin, in a local
# collection: its documentation, its options from the environment, its errors,
# its cache, and its unit tests. CI compares this output with expected.txt.
set -euo pipefail
cd "$(dirname "$0")"
rm -rf out
mkdir -p out
out=$PWD/out
collection=collections/ansible_collections/example/cmdb

# The fake CMDB: mock/cmdb.py, answering out/servers.json behind a bearer token.
export CMDB_TOKEN=test-only-token
cmdb_pid=
start_cmdb() {
  python3 mock/cmdb.py out/servers.json out/requests.log 18230 &
  cmdb_pid=$!
  python3 - <<'PY'
import time, urllib.error, urllib.request
for _ in range(50):
    try:
        urllib.request.urlopen("http://127.0.0.1:18230/html", timeout=1)
        break
    except OSError:
        time.sleep(0.1)
PY
  : >out/requests.log
}
stop_cmdb() {
  if [ -n "$cmdb_pid" ]; then
    kill "$cmdb_pid"
    wait "$cmdb_pid" 2>/dev/null || true
  fi
  cmdb_pid=
}
trap stop_cmdb EXIT

# Prints one line per run: the exit code of ansible-inventory --list, then each
# group with its hosts. Then the warnings and errors, without paths, and the
# requests the CMDB received since the last call. Unless full=1, it leaves out
# the warnings that repeat on every failure: the yaml and ini plugins
# declining the file, and "No inventory was parsed".
show() {
  local label=$1 rc=0 skip='^\[WARNING\]: (Failed to parse inventory with .(yaml|ini). plugin|No inventory was parsed)'
  if [ "${full:-0}" = 1 ]; then skip="^$"; fi
  shift
  ansible-inventory --list "$@" >"$out/list.json" 2>"$out/stderr" || rc=$?
  python3 - "$label" "$rc" "$out/list.json" <<'PY'
import json, sys
label, rc, path = sys.argv[1:]
text = open(path).read()
inv = json.loads(text) if text else {}
groups = [f"{g}[{','.join(inv[g]['hosts'])}]" for g in sorted(inv)
          if g not in ("_meta", "all", "ungrouped") and inv[g].get("hosts")]
print(f"  {label}: exit {rc}, {' '.join(groups) or 'no hosts'}")
PY
  grep -h -e '^\[WARNING\]' -e '^\[ERROR\]' "$out/stderr" | { grep -Ev "$skip" || true; } \
    | sed "s|$PWD/||g; s|^|    |" || true
  if [ -s "$out/requests.log" ]; then
    sed 's/^/    CMDB got: /' "$out/requests.log"
    : >"$out/requests.log"
  fi
}

# Prints the variables ansible-inventory --host gives one host, one per line.
host_vars() {
  ansible-inventory --host "$1" "${@:2}" 2>/dev/null | python3 -c 'import json, sys
for key, value in sorted(json.load(sys.stdin).items()):
    value = value["__ansible_unsafe"] if isinstance(value, dict) and "__ansible_unsafe" in value else value
    print(f"    {key}: {value}")'
  : >"$out/requests.log"
}

echo "== 1. What ansible-core already has: ansible-doc -t inventory -l"
mkdir -p out/no-collections
ANSIBLE_COLLECTIONS_PATH=out/no-collections ansible-doc -t inventory -l --json 2>/dev/null | python3 -c '
import json, sys
for name, description in sorted(json.load(sys.stdin).items()):
    print(f"  {name:<34} {description}")'

echo
echo "== 2. No code of our own: an inventory script, then the constructed plugin"
cp cmdb/v1.json out/servers.json
start_cmdb
export CMDB_URL=http://127.0.0.1:18230/api/servers
show "script + constructed" -i nocode/inventory
echo "  db1's variables:"
host_vars db1 -i nocode/inventory

echo
echo "== 3. The plugin in a collection: its documentation (ansible-doc)"
doc_py=$(cat <<'PY'
import json, sys
doc = json.load(sys.stdin)["example.cmdb.cmdb"]["doc"]
print("  " + doc["short_description"] + "; options, with the cache and constructed ones merged in:")
for name, option in sorted(doc["options"].items()):
    facts = ["required"] if option.get("required") else []
    if "default" in option:
        facts.append(f"default {option['default']}")
    facts += [env["name"] for env in option.get("env", [])]
    print(f"  {name:<17} {', '.join(facts)}")
PY
)
ansible-doc -t inventory example.cmdb.cmdb --json 2>/dev/null | python3 -c "$doc_py"

echo
echo "== 4. The plugin reads the CMDB"
show "hosts.cmdb.yml" -i inventory/hosts.cmdb.yml --flush-cache
echo "  db1's variables:"
host_vars db1 -i inventory/hosts.cmdb.yml
show "env-only.cmdb.yml: url from CMDB_URL" -i pitfalls/env-only.cmdb.yml
full=1 show "cmdb-hosts.yml: verify_file declines the name" -i pitfalls/cmdb-hosts.yml

echo
echo "== 5. Errors: the plugin raises AnsibleParserError with what went wrong"
(unset CMDB_TOKEN; show "CMDB_TOKEN unset" -i pitfalls/env-only.cmdb.yml)
CMDB_TOKEN= show "CMDB_TOKEN empty" -i pitfalls/env-only.cmdb.yml
CMDB_TOKEN=wrong show "wrong token" -i pitfalls/env-only.cmdb.yml
show "an HTML answer" -i pitfalls/html.cmdb.yml
cp cmdb/no-name.json out/servers.json
show "a server without a name" -i pitfalls/env-only.cmdb.yml
ANSIBLE_INVENTORY_ANY_UNPARSED_IS_FAILED=true show "the same, any_unparsed_is_failed" -i pitfalls/env-only.cmdb.yml
cp cmdb/v1.json out/servers.json
show "keyed_groups on a missing field" -i pitfalls/rack.cmdb.yml
show "the same, strict: true" -i pitfalls/rack-strict.cmdb.yml

echo
echo "== 6. The cache: the CMDB changes (app2 retired, app3 added), then goes down"
cp cmdb/v2.json out/servers.json
show "from the cache" -i inventory/hosts.cmdb.yml
show "--flush-cache" -i inventory/hosts.cmdb.yml --flush-cache
stop_cmdb
show "CMDB down, from the cache" -i inventory/hosts.cmdb.yml
show "CMDB down, --flush-cache" -i inventory/hosts.cmdb.yml --flush-cache

echo
echo "== 7. Unit tests, with the HTTP call mocked (pytest)"
(cd "$collection" && python3 -m pytest -q -p no:cacheprovider tests/unit) >out/pytest.txt 2>&1 || true
grep -E '(passed|failed|error)' out/pytest.txt | sed -E 's/ in [0-9.]+s//; s/=+//g; s/^ *| *$//g; s/^/  /'
