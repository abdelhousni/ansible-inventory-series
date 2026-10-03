#!/usr/bin/env bash
# Shows what each way of storing a secret in the inventory reveals: to a
# search, to ansible-inventory with and without the vault password, to a
# playbook's output, and to git when the secret changes. The vault passwords
# in vault-pass/ are test values committed on purpose. CI compares this
# output with expected.txt.
set -euo pipefail
cd "$(dirname "$0")"
rm -rf out
mkdir out
pw=(--vault-password-file vault-pass/test.txt)
clear() { if grep -q "$2" "$1"; then echo "in clear"; else echo "not in clear"; fi; }

echo "searching the repository for postgresql_password:"
for d in alias no-alias; do
  echo "  $d: $(grep -rl postgresql_password "$d/inventory" | sed "s#^$d/inventory/##" | paste -sd' ' -)"
done

echo
echo "ansible-inventory --host db1, without the vault password:"
for d in alias inline; do
  ansible-inventory -i "$d/inventory" --host db1 >"out/$d-nopw.json" 2>"out/$d-nopw.err" && rc=0 || rc=$?
  if [ "$rc" = 0 ]; then
    echo "  $d: exit 0, postgresql_password is $(jq -r '.postgresql_password | if type == "object" then "an encrypted blob (" + (keys | join(",")) + ")" else type end' "out/$d-nopw.json")"
  else
    echo "  $d: exit $rc, $(grep -o 'Attempting to decrypt but no vault secrets found' "out/$d-nopw.err")"
  fi
done

echo
echo "ansible-inventory --host db1, with the vault password:"
for d in alias inline; do
  ansible-inventory -i "$d/inventory" --host db1 "${pw[@]}" >"out/$d-pw.json" 2>/dev/null
  echo "  $d: keys $(jq -r 'keys | map(select(startswith("ansible_") | not)) | join(", ")' "out/$d-pw.json"); the secret is $(clear "out/$d-pw.json" S3cret-db)"
done

echo
echo "a playbook using postgresql_password (alias):"
ansible-playbook -i alias/inventory use.yml "${pw[@]}" >out/use.log 2>&1
echo "  careless task: the secret is $(sed -n '/careless/,/^$/p' out/use.log | clear /dev/stdin S3cret-db)"
echo "  no_log task: $(sed -n '/with no_log/,/^$/p' out/use.log | grep -E '^(ok|changed)' | paste -sd' ' -), the secret is $(sed -n '/with no_log/,/^$/p' out/use.log | clear /dev/stdin S3cret-db)"

echo
echo "changing the password, then rekeying:"
cp alias/inventory/group_vars/postgresql/vault.yml out/vault.yml
lines=$(wc -l <out/vault.yml)
ansible-vault decrypt "${pw[@]}" --output - out/vault.yml 2>/dev/null | sed 's/S3cret-db/N3w-s3cret/' >out/vault.plain
ansible-vault encrypt "${pw[@]}" --output out/vault-new.yml out/vault.plain >/dev/null 2>&1
echo "  vault.yml: $(diff out/vault.yml out/vault-new.yml | grep -c '^>') of $lines lines changed for a one-value change"
cp out/vault-new.yml out/vault-rekeyed.yml
ansible-vault rekey "${pw[@]}" --new-vault-password-file vault-pass/prod.txt out/vault-rekeyed.yml >/dev/null 2>&1
echo "  after rekey: $(diff out/vault-new.yml out/vault-rekeyed.yml | grep -c '^>') of $lines lines changed, value unchanged"
grep -n '!vault' inline/inventory/group_vars/postgresql/vars.yml | sed 's/^/  inline: line /; s/:postgresql_password: !vault |/ holds the encrypted value; the lines around it stay plaintext/'

echo
echo "vault IDs: prod and staging encrypted with different passwords"
echo "  headers: $(head -qn1 vault-ids/inventory/group_vars/{prod,staging}/vault.yml | paste -sd' ' -)"
ids=(--vault-id prod@vault-pass/prod.txt)
ansible-playbook -i vault-ids/inventory use.yml "${ids[@]}" --vault-id staging@vault-pass/staging.txt >out/ids-both.log 2>&1 \
  && echo "  both passwords: exit 0" || echo "  both passwords: exit $?"
ansible-playbook -i vault-ids/inventory use.yml "${ids[@]}" --limit prod >out/ids-prod.log 2>&1 \
  && echo "  prod password, --limit prod: exit 0" || echo "  prod password, --limit prod: exit $?"
ansible-playbook -i vault-ids/inventory use.yml "${ids[@]}" >out/ids-missing.log 2>&1 && rc=0 || rc=$?
echo "  prod password, all hosts: exit $rc, $(grep -o 'Decryption failed (no vault secrets were found that could decrypt)' out/ids-missing.log | head -n 1)"
