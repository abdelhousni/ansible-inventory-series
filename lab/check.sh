#!/usr/bin/env bash
# Reports what the examples need and whether this machine has it. Run it from
# the repository root, before the first run.sh. It changes nothing.
set -uo pipefail
cd "$(dirname "$0")/.."
missing=0
ok() { printf '  ok       %s\n' "$1"; }
ko() { printf '  MISSING  %s: %s\n' "$1" "$2"; missing=1; }

echo "Needed by every example:"
if [ -x .venv/bin/python ] && .venv/bin/python -c 'import sys; sys.exit(sys.version_info < (3, 12))'; then
  ok ".venv with Python $(.venv/bin/python -c 'import platform; print(platform.python_version())')"
else
  ko ".venv with Python 3.12 or newer" "python3.12 -m venv .venv (ansible-core 2.21 needs 3.12)"
fi
if [ -x .venv/bin/ansible-playbook ] && .venv/bin/ansible --version 2>/dev/null | grep -q 'core 2.21.4'; then
  ok "ansible-core 2.21.4 in .venv"
else
  ko "ansible-core 2.21.4 in .venv" ".venv/bin/pip install --require-hashes -r requirements.txt"
fi
if [ -d collections/ansible_collections/community/docker ]; then
  ok "community.docker in collections/"
else
  ko "community.docker in collections/" ".venv/bin/ansible-galaxy collection install -r requirements.yml -p collections"
fi

echo "Needed by some examples:"
if [ -d collections/ansible_collections/theforeman/foreman ]; then
  ok "theforeman.foreman in collections/ (16)"
else
  ko "theforeman.foreman in collections/ (16)" ".venv/bin/ansible-galaxy collection install -r requirements.yml -p collections"
fi
if [ -x .venv/bin/python ] && .venv/bin/python -c 'import requests' 2>/dev/null; then
  ok "requests in .venv (16, 17, 18, 20)"
else
  ko "requests in .venv (16, 17, 18, 20)" ".venv/bin/pip install --require-hashes -r requirements.txt"
fi
command -v jq >/dev/null && ok "jq (03, 08, 09, 10, 16, 18, 24, 25)" || ko "jq (03, 08, 09, 10, 16, 18, 24, 25)" "install your distribution's jq package"
for c in general proxmox; do
  if [ -d "collections/ansible_collections/community/$c" ]; then
    ok "community.$c in collections/ (17$([ $c = proxmox ] && echo ', 18, 20'))"
  else
    ko "community.$c in collections/ (17$([ $c = proxmox ] && echo ', 18, 20'))" ".venv/bin/ansible-galaxy collection install -r requirements.yml -p collections"
  fi
done

if [ -x .venv/bin/python ] && .venv/bin/python -c 'import pytest' 2>/dev/null; then
  ok "pytest in .venv (23)"
else
  ko "pytest in .venv (23)" ".venv/bin/pip install --require-hashes -r requirements.txt"
fi
if [ -x .venv/bin/check-jsonschema ] && .venv/bin/check-jsonschema --version 2>/dev/null | grep -q '0.38.2'; then
  ok "check-jsonschema 0.38.2 in .venv (25)"
else
  ko "check-jsonschema 0.38.2 in .venv (25)" ".venv/bin/pip install --require-hashes -r requirements.txt"
fi
command -v ssh >/dev/null && command -v ssh-keygen >/dev/null && ok "OpenSSH client (04, 13)" \
  || ko "OpenSSH client (04, 13)" "install openssh-client (Debian, Ubuntu) or openssh-clients (Fedora, RHEL)"

# 04 and 07 start their target hosts with one runtime: LAB_RUNTIME, or the
# first available (lab/runtime.sh). Only the selected one has to work.
echo "Lab runtime for 04 and 07 (LAB_RUNTIME=${LAB_RUNTIME:-auto}):"
runtimes=""
if command -v docker >/dev/null && docker info >/dev/null 2>&1; then
  runtimes="$runtimes docker"
  printf '  found    Docker %s\n' "$(docker version --format '{{.Server.Version}}' 2>/dev/null)"
fi
if command -v podman >/dev/null && podman info >/dev/null 2>&1; then
  runtimes="$runtimes podman"
  printf '  found    Podman %s\n' "$(podman version --format '{{.Client.Version}}' 2>/dev/null)"
fi
if command -v kind >/dev/null && command -v kubectl >/dev/null \
  && kind get clusters 2>/dev/null | grep -qx "${LAB_KIND_CLUSTER:-lab}" && kubectl get nodes >/dev/null 2>&1; then
  runtimes="$runtimes kubernetes"
  printf '  found    kind cluster %s, kubectl %s\n' "${LAB_KIND_CLUSTER:-lab}" \
    "$(kubectl version --client -o json 2>/dev/null | python3 -c 'import json,sys; print(json.load(sys.stdin)["clientVersion"]["gitVersion"])')"
fi
selected=${LAB_RUNTIME:-}
[ -z "$selected" ] && selected=$(echo "$runtimes" | awk '{print $1}')
case " $runtimes " in
  *" ${selected:-none} "*) ok "selected: $selected" ;;
  *) ko "selected: ${selected:-none}" "start Docker or Podman, create the kind cluster (kind create cluster --name lab), or change LAB_RUNTIME" ;;
esac
for c in containers.podman:podman kubernetes.core:kubernetes; do
  coll=${c%%:*} rt=${c##*:}
  [ "$selected" = "$rt" ] || continue
  if [ -d "collections/ansible_collections/${coll%%.*}/${coll#*.}" ]; then
    ok "$coll in collections/ (for $rt)"
  else
    ko "$coll in collections/ (for $rt)" ".venv/bin/ansible-galaxy collection install -r requirements.yml -p collections"
  fi
done
exit "$missing"
