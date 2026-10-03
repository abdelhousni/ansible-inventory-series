#!/usr/bin/env bash
# Starts the two containers behind db1 and app1, connects to every host,
# prints where each connection landed, then what happens when a connection
# variable is missing or ignored. Needs Docker, Podman or a kind cluster: see
# ../lab/runtime.sh and LAB_RUNTIME. CI compares this output with expected.txt,
# or expected-$LAB_RUNTIME.txt where the runtime changes it.
set -euo pipefail
cd "$(dirname "$0")"
rm -rf out
mkdir out
# shellcheck source=../lab/runtime.sh
. ../lab/runtime.sh
[ -n "$LAB_INVENTORY" ] && export ANSIBLE_INVENTORY="inventory,$LAB_INVENTORY"
cleanup() { lab_rm inv04-db1 inv04-app1; }
trap cleanup EXIT
cleanup

# A key pair for this run only: nothing secret is committed.
ssh-keygen -q -t ed25519 -N '' -f out/id_ed25519
lab_build inv04-target containers/Containerfile containers
lab_run inv04-db1 inv04-target db1-container 2222
lab_exec inv04-db1 install -d -o dbadmin -g dbadmin -m 0700 /home/dbadmin/.ssh
lab_cp out/id_ed25519.pub inv04-db1:/home/dbadmin/.ssh/authorized_keys
lab_exec inv04-db1 chown dbadmin:dbadmin /home/dbadmin/.ssh/authorized_keys
lab_run inv04-app1 inv04-target app1-container "" sleep infinity
for _ in $(seq 1 30); do
  ssh -q -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -i out/id_ed25519 -p 2222 dbadmin@127.0.0.1 true 2>/dev/null && break
  sleep 1
done

ansible-playbook whoami.yml >/dev/null
cat out/whoami.txt

echo
echo "db1 with ansible_host left at its default, the inventory name:"
ansible db1 -m ansible.builtin.ping -e ansible_host=db1 >out/no-host.txt 2>&1 || true
grep -o -m 1 'UNREACHABLE' out/no-host.txt | sed 's/^/  /' || true
grep -o -m 1 'Could not resolve hostname db1' out/no-host.txt | sed 's/^/  /' || true

echo
echo "app1 with ansible_host left at its default, the inventory name:"
ansible app1 -m ansible.builtin.ping -e ansible_host=app1 >out/no-container.txt 2>&1 || true
grep -o -m 1 'UNREACHABLE' out/no-container.txt | sed 's/^/  /' || true
grep -o -m 1 'Failed to create temporary directory\.' out/no-container.txt | sed 's/^/  /' || true
# The same mistake as Podman reports it.
grep -o -m 1 "Container 'app1' not found" out/no-container.txt | sed 's/^/  /' || true

echo
echo "jump1 with ansible_user=nobody, which the local connection ignores:"
ansible jump1 -m ansible.builtin.command -a 'id -un' -e ansible_user=nobody >out/local-user.txt 2>&1
if grep -qx nobody out/local-user.txt; then echo "  ran as nobody"; else echo "  ran as the controller's own user"; fi
