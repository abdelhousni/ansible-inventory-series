#!/usr/bin/env bash
# Targets hosts with patterns: unions, intersections, exclusions, indexes and
# regexes, the order Ansible applies them in, --limit (also from a file), a
# second inventory source and constructed groups. CI compares this output
# with expected.txt.
set -euo pipefail
cd "$(dirname "$0")"
rm -rf out
mkdir out

# Prints the hosts a pattern matches, on one line, in Ansible's order.
hosts() {
  ansible "$@" --list-hosts >out/hosts.out 2>out/hosts.err || { echo "  exit $?"; cat out/hosts.err; return; }
  printf '  %-34s %s\n' "$*" "$(tail -n +2 out/hosts.out | xargs)"
}

echo "== 1. Groups, unions, intersections, exclusions"
hosts all
hosts app
hosts 'app:db'
hosts 'app:&prod'
hosts 'app:!staging'
hosts 'app,db'

echo
echo "== 2. Order: unions first, then intersections, then exclusions"
hosts 'prod:&app:db'
hosts 'app:db:&prod'
hosts '!staging:app'

echo
echo "== 3. Indexes, wildcards, regexes"
hosts 'app[0]'
hosts 'app[1:]'
hosts 'app[-1]'
hosts 'stg-*'
hosts '~^(app|db)\d$'

echo
echo "== 4. A second source: 20-extra.yml adds app3 to app"
hosts app -i inventory/10-hosts.yml
hosts app -i inventory/10-hosts.yml -i inventory/20-extra.yml

echo
echo "== 5. Constructed groups from a variable"
hosts env_prod
hosts env_staging
hosts 'app:!env_prod:!env_staging'

echo
echo "== 6. strict: true on a host without env"
ansible-inventory -i pitfalls/strict/inventory --graph >out/strict.out 2>out/strict.err
echo "  warnings: $(grep -c '^\[WARNING\]' out/strict.err)"
grep -o 'Could not generate group for host [^:]*: .*' out/strict.err | sort -u | sed 's/^/  /'
echo "  groups still built: $(grep -o 'env_[a-z]*' out/strict.out | sort -u | xargs)"

echo
echo "== 7. --limit narrows the play's hosts: app"
play() {
  ansible-playbook site.yml "$@" >out/play.out 2>&1
  echo "  --limit ${2:-(none)}:"
  grep -o "msg: '.*'" out/play.out | sed "s/msg: '\\(.*\\)'/    \\1/"
}
play
play --limit 'staging'
play --limit '@limit.txt'
echo "  limit.txt holds: $(xargs <limit.txt)"

echo
echo "== 8. The whole tree"
ansible-inventory --graph >out/graph.out 2>&1
cat out/graph.out
