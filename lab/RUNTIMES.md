# Lab runtimes: provisioning each one locally

Examples 04 and 07 start their target hosts as containers. They run on
Docker, Podman or a kind cluster, chosen with `LAB_RUNTIME` (see
[`runtime.sh`](runtime.sh)). This page is the step-by-step setup for each
one, so you can provision any of them when you need it. Every other example
needs none of this.

The steps were tested on Ubuntu 24.04, with the versions in the README's
"Local lab" table. Commands run from the repository's root.

## 0. The common base

Every runtime needs the base lab first:

```sh
python3.12 -m venv .venv
.venv/bin/pip install --require-hashes -r requirements.txt
.venv/bin/ansible-galaxy collection install -r requirements.yml -p collections
export PATH="$PWD/.venv/bin:$PATH"
./lab/check.sh
```

`requirements.yml` includes the connection collections of every runtime:
`community.docker`, `containers.podman` and `kubernetes.core`.

## 1. Docker (the default)

1. Install Docker Engine (Linux) or Docker Desktop (macOS, Windows), from
   docs.docker.com. On Ubuntu:
   ```sh
   sudo apt-get install -y docker.io
   sudo usermod -aG docker "$USER"    # then log out and back in
   ```
2. Check the daemon answers: `docker info`.
3. Run the examples:
   ```sh
   LAB_RUNTIME=docker ./04-connection-variables/run.sh | diff 04-connection-variables/expected.txt -
   LAB_RUNTIME=docker ./07-facts-or-variables/run.sh | diff 07-facts-or-variables/expected.txt -
   ```
4. Clean up: each `run.sh` removes its containers when it ends. The images
   stay: `docker image rm inv04-target inv07-db1 inv07-db2`.

## 2. Podman

1. Install Podman. On Ubuntu: `sudo apt-get install -y podman`. Rootless
   Podman needs subordinate IDs for your user; check with
   `grep "$USER" /etc/subuid /etc/subgid`, and add them if missing:
   `sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 "$USER"`.
2. Check it runs a container: `podman run --rm docker.io/library/alpine:3.20 true`.
3. Run the examples:
   ```sh
   LAB_RUNTIME=podman ./04-connection-variables/run.sh | diff 04-connection-variables/expected-podman.txt -
   LAB_RUNTIME=podman ./07-facts-or-variables/run.sh | diff 07-facts-or-variables/expected.txt -
   ```
   04 has its own expected output: the connection name and the message for a
   missing container differ (`containers.podman.podman` says *Container
   'app1' not found*).
4. Clean up: the containers go when `run.sh` ends; the images stay:
   `podman image rm inv04-target inv07-db1 inv07-db2`.

Without `LAB_RUNTIME`, `runtime.sh` picks Docker if its daemon answers, and
Podman otherwise.

## 3. Kubernetes (a kind cluster)

kind runs a Kubernetes cluster in Docker containers. The examples build their
images with Docker, load them into the cluster, and run them as pods; Ansible
reaches the pods with `kubectl exec`.

1. Have Docker working (step 1).
2. Install kind and kubectl, checking their checksums:
   ```sh
   mkdir -p "$HOME/bin"
   curl -sSLo "$HOME/bin/kind" https://github.com/kubernetes-sigs/kind/releases/download/v0.30.0/kind-linux-amd64
   curl -sSLo "$HOME/bin/kubectl" https://dl.k8s.io/release/v1.34.1/bin/linux/amd64/kubectl
   echo "517ab7fc89ddeed5fa65abf71530d90648d9638ef0c4cde22c2c11f8097b8889  $HOME/bin/kind" | sha256sum -c
   echo "7721f265e18709862655affba5343e85e1980639395d5754473dafaadcaa69e3  $HOME/bin/kubectl" | sha256sum -c
   chmod +x "$HOME/bin/kind" "$HOME/bin/kubectl"
   export PATH="$HOME/bin:$PATH"
   ```
3. Create the cluster the examples expect, named `lab`
   (`LAB_KIND_CLUSTER` changes the name):
   ```sh
   kind create cluster --name lab --wait 120s
   kubectl get nodes
   ```
4. Run the examples:
   ```sh
   LAB_RUNTIME=kubernetes ./04-connection-variables/run.sh | diff 04-connection-variables/expected-kubernetes.txt -
   LAB_RUNTIME=kubernetes ./07-facts-or-variables/run.sh | diff 07-facts-or-variables/expected.txt -
   ```
   Where an `expected-kubernetes.txt` exists, the runtime changes the output;
   otherwise compare with `expected.txt`, as CI does.
5. Clean up: `run.sh` deletes its pods; to remove the cluster,
   `kind delete cluster --name lab`.

How it differs from Docker and Podman:
- **db1's SSH port** is reached through `kubectl port-forward`, which
  `runtime.sh` starts and stops.
- **`kubectl exec` has no `--user`**: commands run as the image's user, so
  `ansible_user` has no effect on `kubernetes.core.kubectl`.
- **The pod is named by `ansible_kubectl_pod`**, not `ansible_host`.

## 4. Windows with WSL2

Not tested yet: these are the documented routes. All three runtimes should
run inside a WSL2 distribution (Ubuntu 24.04):
- **Docker:** Docker Desktop with WSL2 integration enabled for the
  distribution, or Docker Engine installed inside it (needs systemd:
  `[boot] systemd=true` in `/etc/wsl.conf`, then `wsl --shutdown`).
- **Podman:** `sudo apt-get install -y podman` inside the distribution, as in
  step 2.
- **kind:** on top of either Docker setup, as in step 3.

Clone the repository inside the WSL2 file system (`~/…`), not under
`/mnt/c`: file permissions and the executable bit of `run.sh` don't survive
the Windows file system.

## What CI runs

[`.github/workflows/examples.yml`](../.github/workflows/examples.yml):
- **`example`** runs every example with Docker, the default.
- **`runtime`** runs 04 and 07 with Podman, and with a kind cluster it
  creates from the pinned binaries above.

## Checking the setup

`./lab/check.sh` lists the runtimes it finds, and the one selected:

```text
Lab runtime for 04 and 07 (LAB_RUNTIME=auto):
  found    Docker 29.6.2
  found    Podman 4.9.3
  ok       selected: docker
```
