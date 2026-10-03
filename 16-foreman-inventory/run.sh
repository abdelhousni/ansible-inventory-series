#!/usr/bin/env bash
# Runs the Foreman inventory plugin against a fake Foreman: a small Python
# server on 127.0.0.1:18160 that answers with recorded API responses and logs
# each request. Shows the hosts and groups each configuration gives, the
# variables, the requests the plugin makes, and the cache. CI compares this
# output with expected.txt.
set -euo pipefail
cd "$(dirname "$0")"
rm -rf out
mkdir out
export FOREMAN_USER=inventory FOREMAN_PASSWORD=test-only-not-a-secret

python3 mock/foreman.py 18160 out/requests.log &
mock=$!
trap 'kill "$mock"' EXIT
for _ in $(seq 50); do
  python3 -c 'import socket; socket.create_connection(("127.0.0.1", 18160)).close()' 2>/dev/null && break
  sleep 0.1
done

# Runs ansible-inventory on a source, prints the requests it made to the fake
# Foreman, then truncates the log.
inventory() {
  local name=$1 rc=0
  shift
  ansible-inventory "$@" >"out/$name.out" 2>"out/$name.err" || rc=$?
  [ "$rc" -eq 0 ] || echo "  exit $rc"
  requests
}
requests() {
  echo "  requests to Foreman: $(wc -l <out/requests.log)"
  sort out/requests.log | uniq -c | sed -E 's/^ *([0-9]+) /    \1x /'
  : >out/requests.log
}

echo "== 1. The Hosts API: host groups, keyed_groups, groups"
inventory hosts-api -i inventory/hosts-api.foreman.yml --graph
sed 's/^/  /' out/hosts-api.out

echo
echo "== 2. web1's variables: Foreman's fields prefixed, parameters as they are, facts in foreman_facts"
ansible-inventory -i inventory/hosts-api.foreman.yml --host web1 >out/web1.out 2>&1
: >out/requests.log
sed 's/^/  /' out/web1.out

echo
echo "== 3. legacy_hostvars: Foreman's fields in one dict, the parameters in another, groups prefixed fm_"
inventory legacy -i inventory/legacy.foreman.yml --graph
sed 's/^/  /' out/legacy.out
ansible-inventory -i inventory/legacy.foreman.yml --host db1 >out/legacy-db1.out 2>&1
echo "  db1's top-level variables: $(jq -r 'keys | join(", ")' out/legacy-db1.out)"
: >out/requests.log
ansible-playbook -i inventory/legacy.foreman.yml params.yml --limit db1 >out/params.out 2>&1
echo "  params.yml --limit db1, foreman_params | dict2items:"
grep -o 'msg: .*' out/params.out | sed 's/^msg: /    /'
echo "  --limit db1 still asked Foreman for every host:"
requests

echo
echo "== 4. The Reports API: one report, groups for location, organization and content"
inventory reports -i inventory/reports-api.foreman.yml --graph
sed 's/^/  /' out/reports.out

echo
echo "== 5. The cache: the second run makes no request, --flush-cache asks again"
inventory cache1 -i inventory/cached.foreman.yml --graph
echo "  the cache file holds Foreman's answers, by URL:"
jq -r '.__payload__ | fromjson | keys[]' out/cache/* | sed 's/^/    /'
inventory cache2 -i inventory/cached.foreman.yml --graph
cmp -s out/cache1.out out/cache2.out && echo "  same graph from the cache"
inventory cache3 -i inventory/cached.foreman.yml --graph --flush-cache

echo
echo "== 6. Pitfall: the Reports API on a Foreman without foreman_ansible"
inventory plain -i pitfalls/no-foreman-ansible.foreman.yml --graph
grep -E "^\[WARNING\]: (Failed to parse inventory with 'auto'|No inventory)" out/plain.err | sed 's/^/  /'
sed 's/^/  /' out/plain.out

echo
echo "== 7. Pitfall: a file name that doesn't end in foreman.yml"
inventory name -i pitfalls/foreman-inventory.yml --graph
grep -E "^\[WARNING\]: (Failed to parse inventory with 'auto'|No inventory)" out/name.err | sed "s#$PWD/##; s/^/  /"
sed 's/^/  /' out/name.out
