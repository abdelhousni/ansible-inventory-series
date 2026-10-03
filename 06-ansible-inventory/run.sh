#!/usr/bin/env bash
# Debugs a broken inventory with ansible-inventory: --graph, --vars, --list,
# --export, --limit, --host and --playbook-dir, each printing what it shows
# and what it hides. CI compares this output with expected.txt.
set -euo pipefail
cd "$(dirname "$0")"
rm -rf out
mkdir out

# Runs ansible-inventory with output in files (Ansible refuses non-blocking
# stdout), prints the command, its output, and its exit code if not 0.
inv() {
  echo
  echo "\$ ansible-inventory $*"
  if ansible-inventory "$@" >out/cmd.out 2>out/cmd.err; then
    cat out/cmd.out
  else
    echo "exit $?:"
    cat out/cmd.err
  fi
}

echo "== 1. The tree: is every host where it should be?"
inv --graph

echo
echo "== 2. A group_vars directory that matches no group"
ls inventory/group_vars
inv --graph backups
inv --host db1

echo
echo "== 3. Where does a value come from?"
inv --graph --vars postgresql

echo
echo "== 4. --list gives variables per host; --export, per group"
inv --list --yaml --limit db1
inv --list --yaml --limit db1 --export

echo
echo "== 5. --limit: --list obeys it, --graph and --host don't"
inv --graph --limit app
inv --host db1 --limit app
inv --list --limit app --output out/app.json
echo "out/app.json, without _meta:"
python3 -c 'import json; d = json.load(open("out/app.json")); del d["_meta"]; print(json.dumps(d, indent=4))'

echo
echo "== 6. The implicit localhost: --host knows it, --list doesn't"
# Its interpreter is the controller's own, an absolute path: replace it.
inv --host localhost |
  sed 's|"ansible_python_interpreter": "/.*"|"ansible_python_interpreter": "<the controller python>"|'
inv --list --yaml --limit localhost

echo
echo "== 7. group_vars beside the playbook"
ansible-playbook playbooks/versions.yml >out/playbook.out 2>&1
echo "What the playbook sees (out/versions.txt):"
cat out/versions.txt
inv --host db1 --playbook-dir playbooks

echo
echo "== 8. TOML needs an extra Python library"
inv --list --toml
