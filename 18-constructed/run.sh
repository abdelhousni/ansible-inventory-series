#!/usr/bin/env bash
# Builds groups and variables with ansible.builtin.constructed on top of a
# Proxmox VE inventory source (community.proxmox.proxmox, against a mock API):
# keyed_groups from tags, status and OS type, conditional groups, compose,
# use_vars_plugins; then the same options set on the proxmox plugin itself.
# CI compares this output with expected.txt.
set -euo pipefail
cd "$(dirname "$0")"
rm -rf out
mkdir out

# The mock Proxmox VE API, stopped when the script ends.
python3 mock/pve.py 18180 &
mock=$!
trap 'kill "$mock"' EXIT
for _ in $(seq 50); do
  python3 -c 'import socket; socket.create_connection(("127.0.0.1", 18180), 1)' 2>/dev/null && break
  sleep 0.1
done

# Prints each group whose name matches a regex, with its hosts, from
# ansible-inventory --list with the given sources.
groups() {
  local regex=$1
  shift
  ansible-inventory "$@" --list >out/list.json 2>out/list.err
  jq -r --arg re "$regex" 'to_entries[] | select(.key | test($re)) | select(.value.hosts)
    | "  \(.key): \(.value.hosts | sort | join(" "))"' out/list.json | sort
}

pve=(-i inventory/10-pve.proxmox.yml)

echo "== 1. The proxmox source alone: its groups, and one guest's variables"
groups . "${pve[@]}"
ansible-inventory "${pve[@]}" --host test1 >out/test1.json 2>out/test1.err
jq -r 'to_entries[] | select(.key | test("tags|status|ostype|ipconfig0")) | "  test1 \(.key) = \(.value | tojson)"' \
  out/test1.json

echo
echo "== 2. constructed on top: keyed_groups"
groups '^(tag|status|os|owner)' -i inventory

echo
echo "== 3. The same keyed groups with the defaults"
groups '^(tag|_os|raw)' "${pve[@]}" -i variants/defaults.yml

echo
echo "== 4. Conditional groups"
groups '^(web_prod|prod_down|local_domain)$' -i inventory

echo
echo "== 5. compose: ansible_host from the IP in the guest's config"
ansible-inventory -i inventory --list >out/list.json 2>out/list.err
wrapped=$(jq -c '._meta.hostvars.test1 | {proxmox_name, ansible_host, owner}' out/list.json)
echo "  --list wraps values from the API: $wrapped"
jq -r '._meta.hostvars | to_entries[] | "  \(.key): \(.value.ansible_host.__ansible_unsafe)"' out/list.json | sort
ansible-inventory -i inventory --host test1 >out/test1.json 2>out/test1.err
echo "  --host test1 prints: $(jq -c .ansible_host out/test1.json)"

echo
echo "== 6. The same options on the proxmox plugin: no group from group_vars/"
groups '^(tag|status|os|owner)' -i direct
ansible-inventory -i direct --host test1 >out/test1.json 2>out/test1.err
echo "  test1 owner = $(jq -r .owner out/test1.json)"
