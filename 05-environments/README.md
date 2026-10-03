# 05: environments

Example for [item 5](https://til.housni.eu/ansible/inventory-environments-directories-or-groups.html).

The same prod and staging hosts, written two ways. `app` and `db` are
functional groups, named for what the hosts do; `prod` and `staging` are
environments.

```
inventories/              one inventory directory per environment
├── prod/
│   ├── hosts.yml         app1, app2 in app; db1 in db
│   └── group_vars/{all,app,db}/
└── staging/
    ├── hosts.yml         stg-app1 in app; stg-db1 in db
    └── group_vars/{all,app,db}/
single/                   one inventory for both
├── hosts.yml             app, db, prod and staging groups
└── group_vars/{all,app,db,prod,staging}/
precedence/               three small inventories: which group wins
```

`app.yml` runs on `hosts: app`, `app_staging.yml` on `hosts: app:&staging`;
each writes the hosts it reached to `out/`. `run.sh` shows:

- with one directory per environment, `-i inventories/staging` reaches only
  staging hosts;
- with one inventory, `hosts: app` reaches both environments, and
  `--limit staging` or `app:&staging` is needed to keep to one; a misspelled
  `--limit` fails with *no hosts to target*;
- when `prod` and `app` set the same variable, `prod` wins because it sorts
  after `app`; a group sorting after `prod`, `web`, would win instead;
  `ansible_group_priority` changes that only when it's set in the hosts
  file, not in `group_vars/`.

`precedence/priority-in-hosts-file/hosts.yml` holds a variable on purpose:
it's the one place `ansible_group_priority` is read.

```sh
./run.sh
```

Compare with [`expected.txt`](expected.txt).
