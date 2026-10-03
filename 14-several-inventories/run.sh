#!/usr/bin/env bash
# Loads several inventory sources at once: a directory mixing a static file and
# a script, what a directory skips, which source wins when two set the same
# variable, file-name and -i order, and where group_vars/ beside each source
# applies once two directories are combined. CI compares this output with
# expected.txt.
set -euo pipefail
cd "$(dirname "$0")"
rm -rf out
mkdir out

# Prints the sources Ansible parsed, in order, and the plugin that took each.
parsed() {
  ansible-inventory "$@" --graph -vvv >out/parsed.out 2>&1
  sed -n "s|^Parsed $PWD/\\(.*\\) inventory source with \\(.*\\) plugin$|  \\1 (\\2)|p" out/parsed.out
}

# Prints the variables named after the host, from ansible-inventory --host.
host_vars() {
  local host=$1
  shift
  ansible-inventory "$@" --host "$host" >out/host.json 2>&1
  printf '  %-9s %s\n' "$host:" "$(python3 -c '
import json, sys
d = json.load(open("out/host.json"))
print(", ".join(f"{k}={v}" for k, v in sorted(d.items()) if not k.startswith("ansible_")))
')"
}

echo "== 1. One directory, a static file and an executable script"
parsed
ansible-inventory --graph >out/graph.out 2>&1
cat out/graph.out

echo
echo "== 2. What the directory holds, and what Ansible skipped (silently, even at -vvv)"
find inventory -maxdepth 1 -type f -printf '  %f\n' | sort

echo
echo "== 3. The same group and host in two sources: the last loaded wins, key by key"
parsed -i conflicts
host_vars app1 -i conflicts
host_vars db1 -i conflicts
ansible db1 -i conflicts -m ansible.builtin.debug \
  -a 'msg="{{ group_names | join(\",\") }}, {{ inventory_file | basename }}"' >out/db1.out 2>&1
echo "  db1 groups and inventory_file: $(sed -n 's/^ *msg: //p' out/db1.out)"

echo
echo "== 4. File names sort as text: 9-override.yml loads after 10-hosts.yml"
parsed -i name-order
host_vars db1 -i name-order

echo
echo "== 5. Separate -i options load in the order given"
host_vars db1 -i conflicts/10-hosts.yml -i conflicts/20-override.yml
host_vars db1 -i conflicts/20-override.yml -i conflicts/10-hosts.yml

echo
echo "== 6. Two directories with -i: each one's group_vars/ applies to every host"
for order in 'prod staging' 'staging prod'; do
  set -- $order
  echo "  -i environments/$1 -i environments/$2"
  host_vars app1 -i "environments/$1" -i "environments/$2"
  host_vars stg-app1 -i "environments/$1" -i "environments/$2"
done

echo
echo "== 7. A script without the execute bit"
ansible-inventory -i pitfalls/not-executable --graph >out/noexec.out 2>&1
grep -o "Unable to parse .*/\\(20-staging.py\\) as an inventory source" out/noexec.out \
  | sed 's|Unable to parse .*/|  warning: Unable to parse |'
echo "  staging hosts: $(grep -c 'stg-' out/noexec.out || true)"

echo
echo "== 8. A README without an extension in the inventory directory"
ansible-inventory -i pitfalls/readme --graph >out/readme.out 2>&1 && echo "  exit 0"
grep -o "Failed to parse inventory with '[a-z]*' plugin: [^.]*" out/readme.out | sed 's/^/  /'
echo "  hosts still loaded: $(grep -o -- '--[a-z0-9-]*$' out/readme.out | cut -c3- | sort -u | xargs)"
if ANSIBLE_INVENTORY_ANY_UNPARSED_IS_FAILED=true ansible-inventory -i pitfalls/readme --graph \
  >out/readme-strict.out 2>&1; then
  echo "  with ANSIBLE_INVENTORY_ANY_UNPARSED_IS_FAILED=true: exit 0"
else
  echo "  with ANSIBLE_INVENTORY_ANY_UNPARSED_IS_FAILED=true: exit $?"
fi
