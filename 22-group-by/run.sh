#!/usr/bin/env bash
# Groups six hosts by operating system with group_by, from recorded facts:
# the groups and the group_vars they bring, with --limit, after a host fails,
# and after the run. Then builds the same groups with constructed's
# keyed_groups. CI compares this output with expected.txt.
set -euo pipefail
cd "$(dirname "$0")"
rm -rf out
mkdir out

# Runs group-by.yml with a fresh fact cache and fresh out/ records, then
# prints the exit code and what the run recorded.
group_by() {
  local rc=0 host
  rm -rf out/facts out/before out/after out/groups.txt out/os_RedHat.txt
  mkdir out/facts out/before out/after
  cp facts/* out/facts/
  ansible-playbook group-by.yml "$@" >out/group-by.log 2>&1 || rc=$?
  echo "  exit $rc"
  grep -h '^\[WARNING\]: Could not match\|^\[ERROR\]: Specified' out/group-by.log | sed 's/^/  /' || true
  [ -e out/groups.txt ] || return 0
  echo "  groups of each host after group_by:"
  sed 's/^/    /' out/groups.txt
  echo "  package_manager, from group_vars/os_<family>/, before and after group_by:"
  for host in $(ls out/after); do
    echo "    $host: $(cat "out/before/$host") -> $(cat "out/after/$host")"
  done
  echo "  play on os_RedHat ran on: $(cat out/os_RedHat.txt 2>/dev/null || echo nothing)"
}

echo "== 1. The facts, recorded in the fact cache (lb2 has none)"
for f in facts/s1_*; do
  python3 -c 'import json, sys
facts = json.loads(json.load(open(sys.argv[1]))["__payload__"])
print("  " + sys.argv[1][len("facts/s1_"):] + ": " + ", ".join(f"{k}={v}" for k, v in sorted(facts.items())))' "$f"
done

echo
echo "== 2. group-by.yml on every host"
group_by

echo
echo "== 3. --limit web1,db1: only the limited hosts are grouped"
group_by --limit web1,db1
echo "  --limit os_RedHat: the group doesn't exist when the limit is read"
group_by --limit os_RedHat

echo
echo "== 4. After the run: no os_ group, no package_manager"
ansible-inventory --graph >out/graph.txt 2>&1
echo "  os_ groups in ansible-inventory --graph: $(grep -c 'os_' out/graph.txt || true)"
ansible-inventory --host db1 >out/db1.json 2>&1
echo "  ansible-inventory --host db1 has package_manager: $(grep -c package_manager out/db1.json || true)"

echo
echo "== 5. A key with a space, as the distribution openSUSE Leap has"
ansible-playbook pitfalls/spaces.yml >out/spaces.log 2>&1
sed 's/^/  /' out/spaces.txt
grep -h '^\[WARNING\]\|^skipping' out/spaces.log | sed 's/^/  /'

echo
echo "== 6. A key with no default: lb2, without facts, fails and leaves the run"
rc=0
mkdir out/no-default
ansible-playbook pitfalls/no-default.yml >out/no-default.log 2>&1 || rc=$?
echo "  exit $rc"
grep -o '^fatal: \[[a-z0-9]*\]: FAILED' out/no-default.log | sed 's/^/  /'
echo "  hosts that ran the second play, with their groups:"
for host in $(ls out/no-default); do
  echo "    $host: $(cat "out/no-default/$host")"
done

echo
echo "== 7. The same groups from constructed's keyed_groups, when the inventory is parsed"
ansible-inventory -i inventory -i keyed/constructed.yml --graph by_os >out/keyed.txt 2>&1
sed 's/^/  /' out/keyed.txt
ansible -i inventory -i keyed/constructed.yml os_RedHat --list-hosts >out/keyed-limit.txt 2>&1
echo "  os_RedHat, usable as a pattern or a --limit:$(sed -n 's/^ *\([a-z0-9]*\)$/ \1/p' out/keyed-limit.txt | tr -d '\n')"
