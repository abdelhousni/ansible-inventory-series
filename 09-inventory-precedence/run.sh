#!/usr/bin/env bash
# Peels one variable back level by level, shows where ansible_group_priority
# applies and where it doesn't, then debugs and fixes a real conflict. Every
# value comes from ansible-inventory --host. CI compares this output with
# expected.txt.
set -euo pipefail
cd "$(dirname "$0")"
rm -rf out
mkdir out
value() { ansible-inventory -i "$1" --host "$2" 2>/dev/null | jq -c ".$3"; }

echo "levels: postgresql_max_connections for db1, removing the winning level each time"
cp -r levels/inventory out/peel
for step in host_vars/db1 group_vars/db group_vars/postgresql group_vars/backup; do
  echo "  db1: $(value out/peel db1 postgresql_max_connections)   (next removed: $step)"
  rm "out/peel/$step/postgresql.yml"
done
echo "  db1: $(value out/peel db1 postgresql_max_connections)   (all only)"
echo "  db2, no host_vars: $(value levels/inventory db2 postgresql_max_connections)"

echo
echo "a dict set in all and in postgresql:"
echo "  postgresql_conf for db2: $(value levels/inventory db2 postgresql_conf)"

echo
echo "ansible_group_priority: 10 on backup (depth 1)"
echo "  against postgresql, same depth:  $(value priority/same-depth db1 postgresql_max_connections)"
echo "  against db, depth 2:             $(value priority/across-depths db1 postgresql_max_connections)"

echo
echo "conflict: db1 is in backup, which needs postgresql_wal_level: replica"
for v in before priority-only restructured; do
  echo "  $v: db1 $(value "conflict/$v" db1 postgresql_wal_level), db2 $(value "conflict/$v" db2 postgresql_wal_level)"
done
echo "  ansible-inventory --graph --vars, before:"
ansible-inventory -i conflict/before --graph --vars 2>/dev/null | grep -v ansible_ | sed 's/^/    /'
