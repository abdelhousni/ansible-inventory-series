#!/usr/bin/env bash
# Runs, with ansible-core alone, the ansible-inventory commands that AWX (the
# upstream of Ansible Automation Platform's automation controller) runs for an
# inventory source from a project and for a constructed inventory, as its
# source builds them. No AWX or AAP runs here. CI compares this output with
# expected.txt.
set -euo pipefail
cd "$(dirname "$0")"
rm -rf out
mkdir out

# The environment AWX sets for every inventory update (STANDARD_INVENTORY_UPDATE_ENV).
awx_env=(
  ANSIBLE_INVENTORY_UNPARSED_FAILED=True
  ANSIBLE_INVENTORY_EXPORT=True
  ANSIBLE_VERBOSE_TO_STDERR=True
  ANSIBLE_HOST_PATTERN_MISMATCH=error
)

# Prints each group with its hosts and its variables, from ansible-inventory --list JSON.
groups() {
  jq -r 'del(._meta) | to_entries[]
    | "  \(.key): hosts \(.value.hosts // [] | join(",") | if . == "" then "-" else . end)"
      + (if .value.vars then ", vars \(.value.vars | tojson)" else "" end)' "$1"
}
# Prints each host's variables, from ansible-inventory --list JSON.
hostvars() {
  jq -r '._meta.hostvars | to_entries[] | "  \(.key): \(.value | tojson)"' "$1"
}

echo "== 1. An inventory source from a project: ansible-inventory --list --export -i <source_path>"
env "${awx_env[@]}" ansible-inventory -i project/inventory --list --export >out/export.json
groups out/export.json
hostvars out/export.json
echo "  without --export, group variables are copied into each host:"
ansible-inventory -i project/inventory --list >out/list.json
hostvars out/list.json

echo
echo "== 2. A smart inventory's host_filter groups__name=db, as a pattern"
ansible all -i project/inventory --limit db --list-hosts >out/smart.out
sed 's/^ */  /' out/smart.out

echo
echo "== 3. A constructed inventory: -i each input inventory, then -i the source_vars, then --limit"
env "${awx_env[@]}" ansible-inventory -i constructed/east.ini -i constructed/west.ini -i constructed/constructed.yml \
  --list --export --limit shutdown_in_product_dev >out/constructed.json
groups out/constructed.json
hostvars out/constructed.json
echo "  inputs in the other order, all:vars site:"
ansible-inventory -i constructed/west.ini -i constructed/east.ini -i constructed/constructed.yml \
  --list --export >out/reversed.json
jq -r '"  \(.all.vars.site)"' out/reversed.json

echo
echo "== 4. A typo in the source_vars, with AWX's environment and the demo's limit"
for strict in true false; do
  rc=0
  env "${awx_env[@]}" ansible-inventory -i constructed/east.ini -i constructed/west.ini \
    -i "pitfalls/typo-strict-$strict.yml" --list --limit shutdown_in_product_dev >out/typo.json 2>out/typo.err || rc=$?
  echo "  strict: $strict, exit $rc"
  grep -o "'acount_alias' is undefined" out/typo.err | sort -u | sed 's/^/    /' || true
  grep -o "Could not match supplied host pattern[^.]*" out/typo.err | sort -u | sed 's/^/    /' || true
done
rc=0
env "${awx_env[@]}" ANSIBLE_INVENTORY_ANY_UNPARSED_IS_FAILED=True ansible-inventory -i constructed/east.ini \
  -i constructed/west.ini -i pitfalls/typo-strict-true.yml --list >out/typo.json 2>out/typo.err || rc=$?
echo "  strict: true, no limit, ANSIBLE_INVENTORY_ANY_UNPARSED_IS_FAILED=True: exit $rc"
rc=0
env "${awx_env[@]}" ansible-inventory -i constructed/east.ini \
  -i constructed/west.ini -i pitfalls/typo-strict-true.yml --list >out/typo.json 2>out/typo.err || rc=$?
hosts=$(jq -r '._meta.hostvars | length' out/typo.json)
echo "  strict: true, no limit, AWX's environment only: exit $rc, $hosts hosts"

echo
echo "== 5. A limit that matches nothing"
for env in AWX default; do
  rc=0
  if [ "$env" = AWX ]; then cmd=(env "${awx_env[@]}" ansible-inventory); else cmd=(ansible-inventory); fi
  "${cmd[@]}" -i constructed/east.ini -i constructed/west.ini -i constructed/constructed.yml \
    --list --limit shutdown_in_product_devv >out/nomatch.json 2>out/nomatch.err || rc=$?
  hosts=$(jq -r '._meta.hostvars // {} | length' out/nomatch.json 2>/dev/null || true)
  echo "  $env environment: exit $rc, $([ -n "$hosts" ] && echo "output with $hosts hosts" || echo "no output")"
  grep -o "Could not match supplied host pattern[^.]*" out/nomatch.err | sort -u | sed 's/^/    /' || true
done
