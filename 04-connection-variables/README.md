# 04: connection variables

Example for [item 4](https://til.housni.eu/ansible/inventory-connection-variables-ssh-docker-local.html).

Three hosts, each reached with a different connection plugin. The hosts
file has no variables; each host's connection settings are in
`inventory/host_vars/<host>/ansible.yml`:

| Host | `ansible_connection` | `ansible_host` | `ansible_port` | `ansible_user` |
|---|---|---|---|---|
| `db1` | `ssh` | `127.0.0.1` | `2222` | `dbadmin` |
| `app1` | `community.docker.docker` | `inv04-app1`, a container name | — | `appuser`, inside the container |
| `jump1` | `local` | — | — | — |

`run.sh` needs Docker and an SSH client. It builds
`containers/Containerfile`, starts db1 as an sshd container published on
`127.0.0.1:2222` and app1 as a plain container, generates a key pair for
this run in `out/`, and runs `whoami.yml`, which records from inside each
host which user and machine the connection reached. It then shows three
mistakes:

- db1 without `ansible_host`: SSH tries to resolve `db1`;
- app1 without `ansible_host`: there's no container called `app1`, and the
  error talks about a temporary directory;
- jump1 with `ansible_user=nobody`: the local connection ignores it.

`ansible_ssh_common_args` turns off host key checking for db1 because the
test container gets a new host key on every run. Don't copy that to real
servers.

```sh
./run.sh
```

Compare with [`expected.txt`](expected.txt).
