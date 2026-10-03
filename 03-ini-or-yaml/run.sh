#!/usr/bin/env bash
# Shows that the same hosts file in INI and in YAML gives the same
# inventory, then what each format does with the same variables. CI
# compares this output with expected.txt.
set -euo pipefail
cd "$(dirname "$0")"
rm -rf out
mkdir out

ansible-inventory -i hosts/hosts.ini --list >out/ini.json
ansible-inventory -i hosts/hosts.yml --list >out/yml.json
if cmp -s out/ini.json out/yml.json; then
  echo "hosts.ini and hosts.yml: same ansible-inventory --list output"
else
  echo "hosts.ini and hosts.yml: different"
  diff out/ini.json out/yml.json || true
fi

for inventory in host-line.ini group-vars-section.ini hosts.yml; do
  echo
  echo "inline-vars/$inventory, db1:"
  ansible-playbook -i "inline-vars/$inventory" types.yml -e "types_output=out/$inventory.txt" >/dev/null
  sed 's/^/  /' "out/$inventory.txt"
done

echo
echo "pitfalls/unquoted-space.ini:"
ansible-inventory -i pitfalls/unquoted-space.ini --list >out/space.json 2>out/space.err
grep -o 'Expected key=value host variable assignment, got: [^ ]*' out/space.err | head -n 1 | sed 's/^/  /'
grep -o 'No inventory was parsed.*' out/space.err | sed 's/^/  /'
echo "  exit $(ansible-inventory -i pitfalls/unquoted-space.ini --list >/dev/null 2>&1; echo $?), hosts: $(jq -c '.all' out/space.json)"
ansible-playbook -i pitfalls/unquoted-space.ini pitfalls/touch-db.yml >out/play.txt 2>&1 && rc=0 || rc=$?
echo "  ansible-playbook: exit $rc, $(grep -o 'skipping: no hosts matched' out/play.txt)"
ANSIBLE_INVENTORY_UNPARSED_FAILED=true ansible-playbook -i pitfalls/unquoted-space.ini pitfalls/touch-db.yml \
  >out/play-strict.txt 2>&1 && rc=0 || rc=$?
echo "  with ANSIBLE_INVENTORY_UNPARSED_FAILED=true: exit $rc, $(grep -o 'No inventory was parsed, please check.*' out/play-strict.txt)"
