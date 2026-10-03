#!/usr/bin/env bash
# Checks an inventory without connecting to any host and without the vault
# password: its variables against schema/inventory.schema.json, then its
# groups against policy.yml. Usage: check.sh <inventory> <work dir>.
# Exits 1 if either check fails. This is what the CI workflow runs.
set -uo pipefail
cd "$(dirname "$0")"
inventory=$1
work=$2
mkdir -p "$work"
status=0

if ! ansible-inventory -i "$inventory" --list >"$work/list.json" 2>"$work/list.err"; then
  echo "  ansible-inventory: FAILED"
  sed 's/^/    /' "$work/list.err"
  exit 1
fi
# {group: {host: hostvars}} for every group with hosts, plus all.
jq '._meta.hostvars as $hv
    | (del(._meta) | with_entries(select(.value.hosts) | .value = (.value.hosts | map({(.): $hv[.]}) | add)))
      + {all: $hv}' "$work/list.json" >"$work/inventory.json"

if check-jsonschema --schemafile schema/inventory.schema.json "$work/inventory.json" >"$work/schema.out" 2>&1; then
  echo "  schema: ok"
else
  echo "  schema: FAILED"
  grep '::' "$work/schema.out" | sed "s#^ *$work/inventory.json::#    #" | sort
  status=1
fi

if ansible-playbook -i "$inventory" policy.yml >"$work/policy.out" 2>&1; then
  echo "  policy: ok"
else
  echo "  policy: FAILED"
  sed -n 's/^    msg: /    /p' "$work/policy.out"
  status=1
fi
exit "$status"
