#!/usr/bin/env bash
# A first play creates three VMs on a fake manager and adds them to the
# in-memory inventory with ansible.builtin.add_host; the next play configures
# them in the same run. Shows what the added hosts receive, what --limit does
# to them, that nothing remains after the run, and that add_host runs once
# per play unless looped. CI compares this output with expected.txt.
set -euo pipefail
cd "$(dirname "$0")"
rm -rf out
mkdir out

# Runs a playbook with fresh out/manager/ and out/web/, then prints the exit
# code, Ansible's warnings and skipped plays, and the files each play wrote.
play() {
  local rc=0
  rm -rf out/manager out/web
  mkdir out/manager out/web
  ansible-playbook -i inventory "$@" >out/run.out 2>&1 || rc=$?
  echo "  $*: exit $rc"
  grep -hE '^\[(WARNING|ERROR)\]|^skipping: no hosts' out/run.out | sed 's/^/    /' || true
  for f in out/manager/*.txt; do
    [ -e "$f" ] && echo "    manager created $(basename "$f" .txt): $(cat "$f")"
  done
  for f in out/web/*.txt; do
    [ -e "$f" ] && echo "    configured $(basename "$f" .txt)"
  done
  return 0
}

echo "== 1. Before the run, the inventory holds only the manager"
ansible-inventory -i inventory --graph >out/graph-before.out 2>&1
sed 's/^/  /' out/graph-before.out

echo
echo "== 2. One run: provision, add_host, configure"
play site.yml
echo "  What web01 received:"
sed 's/^/    /' out/web/web01.txt

echo
echo "== 3. After the run, nothing remains: add_host changes the in-memory inventory only"
ansible-inventory -i inventory --graph >out/graph-after.out 2>&1
sed 's/^/  /' out/graph-after.out
play configure.yml

echo
echo "== 4. --limit applies to the added hosts too"
play site.yml --limit manager1
play site.yml --limit manager1,web02
play site.yml --limit 'web*'

echo
echo "== 5. add_host runs once per play, not once per host, unless looped"
rc=0
ansible-playbook -i pitfalls/once-per-play/hosts.yml pitfalls/once-per-play/add.yml >out/once.out 2>&1 || rc=$?
echo "  exit $rc"
grep -E '^ *msg:' out/once.out | sed 's/^ *msg: /  /'
