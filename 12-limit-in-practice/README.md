# 12: --limit in practice

Example for [item 12](https://til.housni.eu/ansible/inventory-limit-in-practice.html).

| Path | What it shows |
|---|---|
| `inventory/` | item 11's hosts: `app` and `db`, `prod` and `staging`, with `env` per environment |
| `site.yml` | a play on `db`, then a play on `app` with `serial: 2` and a `run_once` task |
| `facts.yml` | app hosts reading an inventory variable and a fact of db1 |
| `delegate-facts.yml` | gathering db facts from the app play with `delegate_facts: true` |
| `nothing.yml` | a play whose `hosts:` matches no group |

`run.sh` shows what `--limit` does to each play of `site.yml`, how
`run_once` behaves with `serial`, which variables of a host outside the
limit stay visible, two ways to get its facts back (`delegate_facts` and a
`jsonfile` fact cache in `out/`), and what happens when a limit or a play
matches nothing. `ansible.cfg` sets `forks = 1` so the output order is the
same on every run.

```sh
./run.sh
```

Compare with [`expected.txt`](expected.txt).
