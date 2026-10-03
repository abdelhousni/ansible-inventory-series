#!/usr/bin/env bash
# What --limit does beyond choosing hosts: to each play of a playbook, to
# run_once with serial, to the facts of hosts outside the limit, and when it
# matches nothing. CI compares this output with expected.txt.
set -euo pipefail
cd "$(dirname "$0")"
rm -rf out
mkdir out

# Runs a playbook with output in a file, prints the exit code if not 0, then
# the debug messages, warnings, errors and skipped plays.
play() {
  echo
  echo "\$ ansible-playbook $*"
  local rc=0
  ansible-playbook "$@" >out/play.out 2>&1 || rc=$?
  [ "$rc" -eq 0 ] || echo "exit $rc"
  grep -E "^ +(msg: |- )|^\[(WARNING|ERROR)\]|^skipping: no hosts|^PLAY \[" out/play.out |
    sed -E "s/^ +msg: '?([^']*)'?$/    \1/; s/^ +- '?([^']*)'?$/    \1/; s/ \*+$//"
}

echo "== 1. --limit applies to every play"
# site.yml's two plays target db and app; --list-hosts shows what each keeps.
for pattern in db app; do
  if ansible "$pattern" --limit app --list-hosts >out/list.out 2>&1; then
    echo "  hosts: $pattern, --limit app: $(tail -n +2 out/list.out | xargs)"
  else
    echo "  hosts: $pattern, --limit app: none, and ad hoc ansible exits $?"
  fi
done
play site.yml
play site.yml --limit app

echo
echo "== 2. run_once runs once per serial batch"
play site.yml --limit 'app:!app2'

echo
echo "== 3. Facts of hosts outside the limit"
play facts.yml
play facts.yml --limit app

echo
echo "== 4. Two ways to get them back"
echo "-- gather them from the play that needs them, delegate_facts: true"
play delegate-facts.yml --limit app1
echo "-- or keep facts from an earlier run in a fact cache"
export ANSIBLE_CACHE_PLUGIN=jsonfile ANSIBLE_CACHE_PLUGIN_CONNECTION=out/facts-cache
ansible-playbook facts.yml >/dev/null 2>&1
play facts.yml --limit app
unset ANSIBLE_CACHE_PLUGIN ANSIBLE_CACHE_PLUGIN_CONNECTION

echo
echo "== 5. Matching nothing"
play site.yml --limit dbs
play site.yml --limit 'app1,ap2'
play nothing.yml
