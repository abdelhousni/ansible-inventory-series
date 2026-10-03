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
command -v jq >/dev/null && ok "jq (03, 08)" || ko "jq (03, 08)" "install your distribution's jq package"
command -v ssh >/dev/null && command -v ssh-keygen >/dev/null && ok "OpenSSH client (04)" \
  || ko "OpenSSH client (04)" "install openssh-client (Debian, Ubuntu) or openssh-clients (Fedora, RHEL)"
if ! command -v docker >/dev/null; then
  ko "docker CLI (04, 07)" "install Docker Engine or Docker Desktop"
elif ! docker info >/dev/null 2>&1; then
  ko "Docker daemon (04, 07)" "start it (systemctl start docker), and check your user can reach it"
else
  ok "Docker daemon $(docker version --format '{{.Server.Version}}' 2>/dev/null) (04, 07)"
fi
exit "$missing"
