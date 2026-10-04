# 26: local facts, declared data that looks measured

Example for [item 26](https://til.housni.eu/ansible/inventory-local-facts-facts-d-risks.html),
a follow-up to [item 7](../07-facts-or-variables/).

| Path | What it shows |
|---|---|
| `containers/Containerfile` | the image of both hosts: Debian 12 with the PostgreSQL 15 client |
| `inventory/` | `db-typed` and `db-measured`, with `postgresql_version: 16` declared in `group_vars/postgresql/` |
| `facts.d/typed.fact` | a hand-written INI local fact that says 16 |
| `facts.d/measured.fact` | an executable local fact that runs `psql --version` and prints JSON |
| `drift.yml` | compares the declared version with `ansible_local` |
| `probe.yml` | prints what a play sees of the local fact |
| `pitfalls/host-vars-ansible-local/` | a second source that sets `ansible_local` in `host_vars` |
| `runtimes/` | the inventory overlays for `LAB_RUNTIME=podman` and `kubernetes` |

`run.sh` starts both hosts, copies each local fact into
`/etc/ansible/facts.d/`, and shows:
1. the drift check passing on `db-typed`, which runs 15, and failing on `db-measured`;
2. INI keys lowercased;
3. `ansible_local` staying a top-level variable with `ANSIBLE_INJECT_FACT_VARS=false`;
4. gathered facts beating an `ansible_local` set in `host_vars`;
5. the fact cache keeping a deleted local fact, in `ansible-inventory --host` and in a play that doesn't gather facts.

```sh
./run.sh
```

It needs Docker, Podman or a kind cluster (`LAB_RUNTIME`, see
[`../lab/RUNTIMES.md`](../lab/RUNTIMES.md)). Compare with
[`expected.txt`](expected.txt).
