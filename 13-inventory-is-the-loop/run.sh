#!/usr/bin/env bash
# Provisions five VMs on a fake manager three ways: a loop over a list of VMs
# in the manager's variables, a loop over names that reads each VM's own
# variables, and a play on the VMs delegated to the manager. Compares what each
# gives: where the data lives, --limit, and parallelism. CI compares this
# output with expected.txt.
set -euo pipefail
cd "$(dirname "$0")"
rm -rf out
mkdir out

# Runs one layout's playbook with fresh out/manager/, then prints the exit
# code, the duration as a range, and the VMs the manager recorded.
provision() {
  local layout=$1 rc=0 start end
  shift
  rm -rf out/manager
  mkdir out/manager
  start=$(date +%s)
  ansible-playbook -i "$layout/hosts.yml" "provision-$layout.yml" "$@" >"out/$layout.out" 2>&1 || rc=$?
  end=$(date +%s)
  echo "  $layout${*:+ $*}: exit $rc, $( (( end - start >= 5 )) && echo "5 s or more" || echo "under 5 s")"
  for f in out/manager/*.txt; do
    [ -e "$f" ] && echo "    $(basename "$f" .txt): $(cat "$f")"
  done
  grep -h '^skipping: no hosts' "out/$layout.out" | sed 's/^/    /' || true
}

echo "== 1. Where each VM's name and size are written"
for layout in bad not-so-bad good; do
  echo "  $layout: app3 in $(grep -rlw app3 "$layout" | sort | xargs)"
  echo "  $layout: 4096 in $(grep -rl 4096 "$layout" | sort | xargs)"
done

echo
echo "== 2. All five VMs: the loops run one VM after another, the play runs five at a time"
for layout in bad not-so-bad good; do
  provision "$layout"
done

echo
echo "== 3. --limit db1"
provision bad --limit db1
provision good --limit db1
echo "  bad, the only limit that provisions anything:"
provision bad --limit manager1

echo
echo "== 4. The VMs don't exist yet: gathering facts fails"
rc=0
ansible-playbook -i good/hosts.yml pitfalls/gather-facts.yml >out/gather.out 2>&1 || rc=$?
echo "  exit $rc"
grep -o '^fatal: \[[a-z0-9]*\]: UNREACHABLE' out/gather.out | sort | sed 's/^/  /'
