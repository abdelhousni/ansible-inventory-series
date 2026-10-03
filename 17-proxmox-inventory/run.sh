#!/usr/bin/env bash
# Builds inventories from a Proxmox VE cluster with community.proxmox.proxmox,
# against a local mock of the Proxmox API (mock/server.py, port 18170): guests
# as hosts, the plugin's groups, filters by status and tag, want_facts with
# compose and keyed_groups, and three ways to get an empty inventory with exit
# code 0. CI compares this output with expected.txt.
set -euo pipefail
cd "$(dirname "$0")"
rm -rf out
mkdir out

# The mock accepts any password; the plugin reads it from the environment.
export PROXMOX_PASSWORD=not-a-secret
python3 mock/server.py 18170 out/requests.log &
mock=$!
trap 'kill "$mock"' EXIT
for _ in $(seq 50); do
  (exec 3<>/dev/tcp/127.0.0.1/18170) 2>/dev/null && break
  sleep 0.1
done
kill -0 "$mock"  # stops here if the mock didn't start, port 18170 taken for example

# Prints the hosts a source gives, on one line, sorted.
hosts_of() {
  ansible-inventory -i "$1" --list 2>/dev/null \
    | python3 -c 'import json, sys; print(*sorted(json.load(sys.stdin)["_meta"]["hostvars"]) or ["(none)"])'
}

# Counts the requests the mock received for one ansible-inventory run.
requests_for() {
  : >out/requests.log
  ansible-inventory -i "$1" --list >/dev/null 2>&1
  wc -l <out/requests.log
}

echo "== 1. Guests and nodes as hosts, in the plugin's groups"
ansible-inventory -i inventory/guests.proxmox.yml --graph 2>&1 | sed 's/^/  /'

echo
echo "== 2. Two guests named test-lxc.home.arpa: one host, the variables of the last one read"
ansible-inventory -i inventory/guests.proxmox.yml --host test-lxc.home.arpa 2>/dev/null \
  | python3 -c 'import json, sys; v = json.load(sys.stdin)
print("  proxmox_vmid", v["proxmox_vmid"], "on", v["proxmox_node"], v["proxmox_status"])'

echo
echo "== 3. Filters: running guests tagged test"
echo "  $(hosts_of inventory/running-test.proxmox.yml)"
echo "  a filter on proxmox_tags_parsed without want_facts:"
ansible-inventory -i pitfalls/tags-parsed.proxmox.yml --list >out/tags-parsed.out 2>&1
warnings=$(grep -c 'Could not evaluate host filter' out/tags-parsed.out)
echo "    $warnings warnings, hosts kept: $(hosts_of pitfalls/tags-parsed.proxmox.yml)"

echo
echo "== 4. want_facts: the guests' configuration as variables"
echo "  requests to the API: $(requests_for inventory/guests.proxmox.yml) without facts," \
  "$(requests_for inventory/facts.proxmox.yml) with want_facts," \
  "$(requests_for inventory/post-filter-facts.proxmox.yml) with want_post_filter_facts"
ansible-inventory -i inventory/facts.proxmox.yml --list 2>/dev/null | python3 -c '
import json, sys
inv = json.load(sys.stdin, object_hook=lambda d: d.get("__ansible_unsafe", d))
for host, v in sorted(inv["_meta"]["hostvars"].items()):
    tags = v.get("proxmox_tags_parsed", [])
    print(f"  {host}: ansible_host {v["ansible_host"]}, {v["proxmox_status"]}, tags {tags}")
for group in sorted(g for g in inv if g.startswith("tag_")):
    print(f"  {group}: {" ".join(sorted(inv[group]["hosts"]))}")'
echo "  pattern tag_test:&proxmox_all_running:"
ansible 'tag_test:&proxmox_all_running' -i inventory/facts.proxmox.yml --list-hosts 2>/dev/null | sed 's/^/  /'

echo
echo "== 5. Empty inventories, exit code 0"
rc=0
ansible-inventory -i pitfalls/unnamed.proxmox.yml --list >out/unnamed.out 2>&1 || rc=$?
echo "  a guest with no name: exit $rc, hosts: $(hosts_of pitfalls/unnamed.proxmox.yml)"
grep -m1 -o 'Invalid empty host name provided' out/unnamed.out | sed 's/^/    /'
rc=0
ANSIBLE_INVENTORY_ANY_UNPARSED_IS_FAILED=true ansible-inventory -i pitfalls/unnamed.proxmox.yml --list \
  >/dev/null 2>&1 || rc=$?
echo "  the same with any_unparsed_is_failed: exit $rc"
rc=0
ansible-inventory -i pitfalls/redirect.proxmox.yml --list >out/redirect.out 2>&1 || rc=$?
echo "  plugin: community.general.proxmox: exit $rc, hosts: $(hosts_of pitfalls/redirect.proxmox.yml)"
grep -o 'community.general.proxmox has been deprecated. The proxmox content .* community\.proxmox\.' out/redirect.out \
  | sed 's/^/    /'
grep -m1 -o "Invalid value 'community.general.proxmox' for config 'plugin'" out/redirect.out | sed 's/^/    /'
