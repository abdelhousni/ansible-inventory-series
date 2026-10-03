#!/usr/bin/env bash
# Renders the same postgresql.conf from a messy playbook and a tidy one, shows
# what the inventory can see of each, then where a role's vars/ and an extra
# var land. CI compares this output with expected.txt.
set -euo pipefail
cd "$(dirname "$0")"
rm -rf out
mkdir -p out/messy out/tidy out/constants
pgvars() { ansible-inventory -i "$1/inventory" --host "$2" 2>/dev/null | jq -c 'with_entries(select(.key | startswith("pgconf")))'; }

echo "messy, with group_vars/postgresql setting max_connections to 300:"
echo "  ansible-playbook -i messy/inventory messy/site.yml -e pgconf_port=5433"
ansible-playbook -i messy/inventory messy/site.yml -e pgconf_port=5433 >out/messy.log 2>&1
for h in db1 db2; do echo "  $h.conf: $(grep -v '^#' out/messy/$h.conf | paste -sd' ')"; done
echo "  what the inventory says about db1: $(pgvars messy db1)"

echo
echo "tidy: ansible-playbook -i tidy/inventory tidy/site.yml"
ansible-playbook -i tidy/inventory tidy/site.yml >out/tidy.log 2>&1
for h in db1 db2; do echo "  $h.conf: $(grep -v '^#' out/tidy/$h.conf | paste -sd' ')"; done
echo "  what the inventory says about db1: $(pgvars tidy db1)"
echo "  $(grep -o -m 1 'restart skipped: pgconf_allow_restart is false' out/tidy.log)"

echo
echo "tidy, with the safety switch: -e pgconf_allow_restart=true"
ansible-playbook -i tidy/inventory tidy/site.yml -e pgconf_allow_restart=true >out/switch.log 2>&1
echo "  $(grep -o -m 1 'restart allowed' out/switch.log)"

echo
echo "a role with max_connections in vars/, group_vars/postgresql sets 300:"
ansible-playbook -i tidy/inventory tidy/constants.yml >out/constants.log 2>&1
echo "  db1: $(cat out/constants/db1-constants.txt)"
echo "  what the inventory says about db1: $(pgvars tidy db1 | jq -c '{pgconf_constants_max_connections}')"
ansible-playbook -i tidy/inventory tidy/constants.yml -e pgconf_constants_max_connections=400 >out/constants-e.log 2>&1
echo "  db1 with -e pgconf_constants_max_connections=400: $(cat out/constants/db1-constants.txt)"
