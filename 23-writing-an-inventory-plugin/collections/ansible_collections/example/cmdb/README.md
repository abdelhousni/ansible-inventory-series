# example.cmdb

A local collection with one inventory plugin, `example.cmdb.cmdb`, for the
fake CMDB of example 23 in the Ansible inventory from scratch series. It's
an illustration, not a published collection.

```sh
ansible-doc -t inventory example.cmdb.cmdb
```

Unit tests, from this directory: `python -m pytest tests/unit`.
