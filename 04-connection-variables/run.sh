#!/usr/bin/env bash
# Starts the two containers behind db1 and app1, connects to every host,
# prints where each connection landed, then what happens when a connection
# variable is missing or ignored. Needs Docker. CI compares this output with
# expected.txt.
set -euo pipefail
cd "$(dirname "$0")"
rm -rf out
mkdir out
cleanup() { docker rm -f inv04-db1 inv04-app1 >/dev/null 2>&1 || true; }
trap cleanup EXIT
cleanup

# A key pair for this run only: nothing secret is committed.
ssh-keygen -q -t ed25519 -N '' -f out/id_ed25519
docker build -q -t inv04-target -f containers/Containerfile containers >/dev/null
docker run -d --name inv04-db1 --hostname db1-container -p 127.0.0.1:2222:2222 inv04-target >/dev/null
docker exec inv04-db1 install -d -o dbadmin -g dbadmin -m 0700 /home/dbadmin/.ssh
docker cp out/id_ed25519.pub inv04-db1:/home/dbadmin/.ssh/authorized_keys
docker exec inv04-db1 chown dbadmin:dbadmin /home/dbadmin/.ssh/authorized_keys
docker run -d --name inv04-app1 --hostname app1-container inv04-target sleep infinity >/dev/null
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

echo
echo "jump1 with ansible_user=nobody, which the local connection ignores:"
ansible jump1 -m ansible.builtin.command -a 'id -un' -e ansible_user=nobody >out/local-user.txt 2>&1
if grep -qx nobody out/local-user.txt; then echo "  ran as nobody"; else echo "  ran as the controller's own user"; fi
