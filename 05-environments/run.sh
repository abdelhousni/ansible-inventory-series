#!/usr/bin/env bash
# Runs the same two playbooks against prod and staging written two ways:
# one inventory directory per environment, then one inventory with prod and
# staging groups beside the app and db groups. Then prints which group wins
# when an environment group and a functional group set the same variable.
# CI compares this output with expected.txt.
set -euo pipefail
cd "$(dirname "$0")"
rm -rf out
mkdir out

# Prints the variables of interest that ansible-inventory gives a host.
host_vars() {
  ansible-inventory -i "$1" --host "$2" >out/host.json 2>out/host.err
  grep -E '"(app_log_level|postgresql_max_connections|ansible_group_priority)"' out/host.json \
    | tr -d ' ,' | sed 's/^/    /'
}

echo "== One inventory directory per environment"
for env in prod staging; do
  ansible-playbook -i "inventories/$env" app.yml >out/run.log 2>&1
  echo "-i inventories/$env, hosts: app"
  sed 's/^/  /' "out/app.txt"
done

echo
echo "== One inventory, prod and staging groups"
ansible-playbook -i single app.yml >out/run.log 2>&1
echo "-i single, hosts: app (both environments)"
sed 's/^/  /' out/app.txt
ansible-playbook -i single app.yml --limit staging >out/run.log 2>&1
echo "-i single --limit staging, hosts: app"
sed 's/^/  /' out/app.txt
ansible-playbook -i single app_staging.yml >out/run.log 2>&1
echo "-i single, hosts: app:&staging"
sed 's/^/  /' out/app_staging.txt
echo "-i single --limit stagign (misspelled), hosts: app"
if ansible-playbook -i single app.yml --limit stagign >out/typo.log 2>&1; then
  echo "  exit 0"
else
  echo "  exit $?"
fi
grep -o -m 1 'Could not match supplied host pattern, ignoring: stagign' out/typo.log | sed 's/^/  /' || true
grep -o -m 1 'Specified inventory, host pattern and/or --limit leaves us with no hosts to target\.' out/typo.log \
  | sed 's/^/  /' || true

echo
echo "== Same variable in an environment group and a functional group"
for host in app1 db1 stg-app1 stg-db1; do
  echo "single, $host:"
  host_vars single "$host"
done
for case in web-after-prod priority-in-hosts-file priority-in-group-vars; do
  echo "precedence/$case, app1:"
  host_vars "precedence/$case" app1
done
