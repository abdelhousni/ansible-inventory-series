#!/usr/bin/env bash
# Starts the two containers behind db1 and db2, compares the PostgreSQL
# version the inventory declares with the one each host has installed, then
# shows where facts end up and two ways of mixing them with the inventory.
# Needs Docker, Podman or a kind cluster: see ../lab/runtime.sh and
# LAB_RUNTIME. CI compares this output with expected.txt.
set -euo pipefail
cd "$(dirname "$0")"
rm -rf out
mkdir out
# shellcheck source=../lab/runtime.sh
. ../lab/runtime.sh
[ -n "$LAB_INVENTORY" ] && export ANSIBLE_INVENTORY="inventory,$LAB_INVENTORY"
cleanup() { lab_rm inv07-db1 inv07-db2; }
trap cleanup EXIT
cleanup

for host in db1 db2; do
  lab_build "inv07-$host" "containers/Containerfile.$host" containers
  lab_run "inv07-$host" "inv07-$host" "$host-container"
done

# The names of the variables ansible-inventory --host gives db1.
host_keys() {
  ansible-inventory "$@" --host db1 >out/host.json 2>out/host.err
  python3 -c 'import json, sys; print("  " + ", ".join(sorted(json.load(sys.stdin))))' <out/host.json
}

echo "ansible-inventory --host db1, before any play:"
host_keys

echo
echo "Declared against installed:"
ansible-playbook drift.yml >out/drift.log 2>&1
sed 's/^/  /' out/drift.txt

echo
echo "ansible-inventory --host db1, after the play filled the fact cache:"
host_keys
echo "the same with --export:"
host_keys --export

echo
echo "With the installed version written back into db2's host_vars:"
ansible-playbook -i inventory -i pitfalls/written-back ${LAB_INVENTORY:+-i $LAB_INVENTORY} drift.yml \
  -e drift_report=out/written-back.txt >out/written-back.log 2>&1
sed 's/^/  /' out/written-back.txt

echo
echo "An inventory variable called packages, after package_facts:"
ansible-playbook -i inventory -i pitfalls/fact-named-like-a-variable ${LAB_INVENTORY:+-i $LAB_INVENTORY} packages.yml >out/packages.log 2>&1
sed 's/^/  injected (the default): /' out/packages.txt
grep -o -m 1 'INJECT_FACTS_AS_VARS default to `True` is deprecated' out/packages.log | sed 's/^/  warning: /' || true
ANSIBLE_INJECT_FACT_VARS=false ansible-playbook -i inventory -i pitfalls/fact-named-like-a-variable \
  ${LAB_INVENTORY:+-i $LAB_INVENTORY} packages.yml \
  -e packages_report=out/not-injected.txt >out/not-injected.log 2>&1
sed 's/^/  inject_facts_as_vars=false: /' out/not-injected.txt
