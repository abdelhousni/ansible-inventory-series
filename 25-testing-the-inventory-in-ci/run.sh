#!/usr/bin/env bash
# Tests the inventory the way CI would, with check.sh: a JSON Schema for the
# variables, an assert playbook for the groups. Runs it on the good
# inventory, then on one broken copy per failure case, each built from
# inventory/ with the files in broken/<case>/ laid over it. Needs no vault
# password. CI compares this output with expected.txt.
set -euo pipefail
cd "$(dirname "$0")"
rm -rf out
mkdir out

# Copies inventory/ to out/<name>/inventory, lays <overlay> over it, checks it.
check_copy() {
  local name=$1 overlay=$2
  mkdir -p "out/$name"
  cp -r inventory "out/$name/inventory"
  cp -r "$overlay/." "out/$name/inventory/"
  ./check.sh "out/$name/inventory" "out/$name" && echo "  exit 0" || echo "  exit $?"
}

echo "== The document the schema validates: {group: {host: variables}}"
./check.sh inventory out/good >/dev/null
jq -r 'to_entries[] | "  \(.key): \(.value | keys | join(", "))"' out/good/inventory.json
echo "  db1 has: $(jq -r '.db.db1 | keys | map(select(startswith("ansible_") | not)) | join(", ")' out/good/inventory.json)"
echo "  vault_postgresql_password, without the password: $(jq -r '.db.db1.vault_postgresql_password | keys[0]' \
  out/good/inventory.json), $(jq -r '.db.db1.vault_postgresql_password.__ansible_vault | split(";")[0]' out/good/inventory.json)…"

echo
echo "== inventory/"
./check.sh inventory out/good && echo "  exit 0" || echo "  exit $?"

for dir in broken/*/; do
  case=$(basename "$dir")
  echo
  echo "== broken/$case: $(grep -rh '^# ' "$dir" | head -n 1 | sed 's/^# //')"
  check_copy "$case" "$dir"
done

echo
echo "== pitfalls/whole-file-vault: vault.yml encrypted as a whole, as in item 10"
check_copy whole-file-vault pitfalls/whole-file-vault 2>&1 | sed '/^    Origin\|^ *$/d'
