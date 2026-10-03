# Ansible inventory from scratch: examples

Runnable examples for the **Ansible inventory from scratch** series on
[til.housni.eu](https://til.housni.eu/). Each directory belongs to one entry
of the series, from hosts and groups to dynamic inventory plugins.

| Directory | Entry |
|---|---|

## Running them

Everything runs on the local machine and changes nothing outside the
example's `out/` directory. From the repository root:

```sh
python3 -m venv .venv
.venv/bin/pip install --require-hashes -r requirements.txt
.venv/bin/ansible-galaxy collection install -r requirements.yml -p collections
PATH="$PWD/.venv/bin:$PATH" ./NN-name/run.sh
```

Each example's `run.sh` prints what the entry says, and CI compares that
output with the example's `expected.txt`.

## Related series

The [Shaping data in Ansible](https://github.com/abdelhousni/ansible-data-shaping-series)
examples cover the filters these inventories feed: `hostvars`, `groups` and
`extract`, `groupby`, and building data in one expression.
