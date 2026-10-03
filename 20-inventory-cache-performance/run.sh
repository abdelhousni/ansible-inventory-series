#!/usr/bin/env bash
# Measures what the inventory cache saves with community.proxmox.proxmox, against
# a local mock of the Proxmox API (mock/server.py) holding 120 generated guests
# and answering each request 20 ms late: API requests per run with and without
# facts, with and without the cache, when the cache is rebuilt, wall time as
# bounds and ratios, and what happens when the API is slow or gone.
# CI compares this output with expected.txt.
set -euo pipefail
cd "$(dirname "$0")"
rm -rf out
mkdir out

python3 mock/generate.py 120 >out/api.json
python3 mock/generate.py 120 3 >out/api-slow.json

# The mock accepts any password; the plugin reads it from the environment.
export PROXMOX_PASSWORD=not-a-secret
mocks=()
trap 'kill "${mocks[@]}" 2>/dev/null || true' EXIT
start_mock() {  # PORT LOG API_JSON LATENCY_MS
  python3 mock/server.py "$@" 2>>out/mock.err &
  mocks+=($!)
  for _ in $(seq 50); do
    (exec 3<>"/dev/tcp/127.0.0.1/$1") 2>/dev/null && return
    sleep 0.1
  done
  echo "mock on port $1 did not start" >&2
  exit 1
}
start_mock 18200 out/requests.log out/api.json 20
start_mock 18201 out/requests-slow.log out/api-slow.json 0

# Counts the hosts in an ansible-inventory --list output.
count_hosts() {
  python3 -c 'import json, sys; print(len(json.load(sys.stdin)["_meta"]["hostvars"]))' <"$1"
}

# Runs ansible-inventory on a source; sets rc, requests (logged by the
# mock on port 18200), hosts (in the result) and ms (wall time).
measure() {
  : >out/requests.log
  local t0
  t0=$(date +%s%N)
  rc=0
  ansible-inventory -i "$@" --list >out/inventory.json 2>out/inventory.err || rc=$?
  ms=$((($(date +%s%N) - t0) / 1000000))
  requests=$(wc -l <out/requests.log)
  hosts=$(count_hosts out/inventory.json)
}

echo "== 1. The mock: 2 nodes, 120 guests, 60 of them tagged web"
measure inventory/list.proxmox.yml
echo "  guest lists only: $hosts hosts, $requests requests"
measure inventory/facts.proxmox.yml
echo "  want_facts: $hosts hosts, $requests requests"
measure inventory/post-filter-facts.proxmox.yml
echo "  want_post_filter_facts: $hosts hosts, $requests requests"
uncached_ms=$ms uncached_requests=$requests

echo
echo "== 2. cache: true with the jsonfile cache plugin"
measure inventory/cached.proxmox.yml
echo "  first run, cache empty: $requests requests"
measure inventory/cached.proxmox.yml
echo "  second run: $hosts hosts, $requests request: $(cat out/requests.log)"
cached_ms=$ms
echo "  cache files: $(ls out/cache | wc -l)"
measure inventory/cached.proxmox.yml --flush-cache
echo "  --flush-cache: $requests requests"
touch -d '2 hours ago' out/cache/*
measure inventory/cached.proxmox.yml
echo "  cache file two hours old, cache_timeout 3600: $requests requests"
measure inventory/cached.proxmox.yml
echo "  next run: $requests request"
echo "  cache: true with the default plugin, memory:"
measure pitfalls/memory-cache.proxmox.yml
first=$requests
measure pitfalls/memory-cache.proxmox.yml
echo "    $first requests, then $requests again"

echo
echo "== 3. Wall time, 20 ms per request"
echo "  uncached run at least $uncached_requests x 20 ms:" \
  "$([ "$uncached_ms" -ge $((uncached_requests * 20)) ] && echo yes || echo no)"
echo "  cached run under half the uncached one:" \
  "$([ $((cached_ms * 2)) -lt "$uncached_ms" ] && echo yes || echo no)"

echo
echo "== 4. A slow or absent API"
t0=$(date +%s%N)
rc=0
ansible-inventory -i pitfalls/slow-api.proxmox.yml --list >out/slow.json 2>out/slow.err || rc=$?
ms=$((($(date +%s%N) - t0) / 1000000))
echo "  /nodes 3 s late: exit $rc, $(count_hosts out/slow.json) hosts, waited at least 3 s:" \
  "$([ "$ms" -ge 3000 ] && echo yes || echo no)"
rc=0
timeout 2 ansible-inventory -i pitfalls/slow-api.proxmox.yml --list >/dev/null 2>&1 || rc=$?
echo "  the same under timeout 2: exit $rc"
kill "${mocks[0]}"
wait "${mocks[0]}" 2>/dev/null || true
measure inventory/cached.proxmox.yml
echo "  API down, cache warm, password: exit $rc, $hosts hosts"
grep -m1 -o 'Connection refused' out/inventory.err | sed 's/^/    /'
PROXMOX_PASSWORD='' PROXMOX_TOKEN_ID=inventory PROXMOX_TOKEN_SECRET=not-a-secret measure inventory/cached.proxmox.yml
echo "  API down, cache warm, API token: exit $rc, $hosts hosts"
