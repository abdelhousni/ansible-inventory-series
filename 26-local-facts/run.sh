#!/usr/bin/env bash
# Starts two PostgreSQL 15 hosts, one with a hand-written local fact and one
# with a fact script that measures, then shows what each fact makes a drift
# check believe, and how local facts behave with fact injection, inventory
# variables and the fact cache. Needs Docker, Podman or a kind cluster: see
# ../lab/runtime.sh and LAB_RUNTIME. CI compares this output with expected.txt.
set -euo pipefail
cd "$(dirname "$0")"
rm -rf out
mkdir out
# shellcheck source=../lab/runtime.sh
. ../lab/runtime.sh
[ -n "$LAB_INVENTORY" ] && export ANSIBLE_INVENTORY="inventory,$LAB_INVENTORY"
cleanup() { lab_rm inv26-db-typed inv26-db-measured; }
trap cleanup EXIT
cleanup

lab_build inv26-pg15 containers/Containerfile containers
lab_run inv26-db-typed inv26-pg15 db-typed
lab_run inv26-db-measured inv26-pg15 db-measured
lab_cp facts.d/typed.fact inv26-db-typed:/etc/ansible/facts.d/postgresql.fact
lab_cp facts.d/measured.fact inv26-db-measured:/etc/ansible/facts.d/postgresql.fact
lab_exec inv26-db-measured chmod 0755 /etc/ansible/facts.d/postgresql.fact

probe() {
  ansible-playbook "$@" probe.yml >out/probe.log 2>&1
  sed 's/^/  /' out/probe.txt
}

echo "== 1. Both hosts run PostgreSQL 15; the inventory declares 16"
for host in db-typed db-measured; do
  echo "  $host: $(lab_exec "inv26-$host" psql --version | sed -E 's/^[^0-9]* ([0-9]+)\..*/\1/')"
done
echo "The drift check, reading ansible_local:"
ansible-playbook drift.yml >out/drift.log 2>&1
sed 's/^/  /' out/drift.txt

echo
echo "== 2. INI keys come back lowercased: the file says Version"
grep -n '=' facts.d/typed.fact | sed 's/^/  /'
probe

echo
echo "== 3. ANSIBLE_INJECT_FACT_VARS=false: other facts leave the top level, ansible_local stays"
ANSIBLE_INJECT_FACT_VARS=false probe

echo
echo "== 4. host_vars sets ansible_local to 99, against the gathered fact"
rm -rf out/facts
echo "  gathering facts:"
probe -i inventory -i pitfalls/host-vars-ansible-local ${LAB_INVENTORY:+-i $LAB_INVENTORY} | sed 's/^/  /'
rm -rf out/facts
echo "  gather_facts: false, empty fact cache:"
probe -i inventory -i pitfalls/host-vars-ansible-local ${LAB_INVENTORY:+-i $LAB_INVENTORY} \
  -e probe_gather_facts=false | sed 's/^/  /'

echo
echo "== 5. The fact cache keeps a local fact after the file is deleted"
probe >/dev/null
lab_exec inv26-db-typed rm /etc/ansible/facts.d/postgresql.fact
local_fact() {
  ansible-inventory "$@" --host db-typed >out/host.json 2>out/host.err
  python3 -c 'import json, sys; print(json.load(sys.stdin).get("ansible_local", "absent"))' <out/host.json
}
echo "  ansible-inventory --host:          $(local_fact)"
echo "  ansible-inventory --host --export: $(local_fact --export)"
echo "  a play with gather_facts: false:"
probe -e probe_gather_facts=false | sed 's/^/  /'
echo "  a play that gathers facts:"
probe | sed 's/^/  /'
