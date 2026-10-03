#!/usr/bin/env bash
# Prints the role variables each host gets from the inventory directory,
# then what Ansible does with five layouts that look right but aren't. CI
# compares this output with expected.txt.
set -euo pipefail
cd "$(dirname "$0")"
rm -rf out
ansible-playbook vars.yml >/dev/null
cat out/vars.txt
for case in file-beside-directory misspelled-group file-order skipped-files readme-without-extension; do
  echo
  echo "pitfalls/$case, db1:"
  if ansible-inventory -i "pitfalls/$case/inventory" --host db1 >out/host.json 2>out/host.err; then
    sed 's/^/  /' out/host.json
  else
    echo "  failed, exit $?:"
    sed 's/^/  /' out/host.err
  fi
done
