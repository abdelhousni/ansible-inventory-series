#!/usr/bin/env bash
# Prints the inventory as Ansible sees it: the group tree, then what each
# host sees of it. CI compares this output with expected.txt.
set -euo pipefail
cd "$(dirname "$0")"
rm -rf out
echo "ansible-inventory --graph:"
ansible-inventory --graph | sed 's/^/  /'
ansible-playbook groups.yml >/dev/null
cat out/groups.txt
