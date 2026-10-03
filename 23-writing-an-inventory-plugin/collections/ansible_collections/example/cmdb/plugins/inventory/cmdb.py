# -*- coding: utf-8 -*-
# GNU General Public License v3.0+ (see https://www.gnu.org/licenses/gpl-3.0.txt)
"""Inventory plugin for the example's CMDB: one JSON endpoint behind a bearer token."""

from __future__ import annotations

DOCUMENTATION = r"""
name: cmdb
short_description: Hosts from the example's CMDB
version_added: 1.0.0
author:
  - abdel.h (@abdelhousni)
description:
  - 'Reads a JSON document C({"servers": [...]}) from O(url), with a bearer token.'
  - Each server needs a C(name) and a C(role). The plugin adds the server as a host in a group named
    after its role, and sets every other field of the server as a host variable prefixed with C(cmdb_),
    for example C(cmdb_owner).
  - The configuration file name must end with C(cmdb.yml) or C(cmdb.yaml).
  - Supports the inventory cache, and the O(compose), O(groups) and O(keyed_groups) options of the
    P(ansible.builtin.constructed#inventory) plugin.
extends_documentation_fragment:
  - ansible.builtin.constructed
  - ansible.builtin.inventory_cache
options:
  plugin:
    description: The name of this plugin, so that the P(ansible.builtin.auto#inventory) plugin hands it the file.
    required: true
    type: str
    choices: [example.cmdb.cmdb]
  url:
    description: The URL of the CMDB's list of servers.
    required: true
    type: str
    env:
      - name: CMDB_URL
  token:
    description:
      - The bearer token sent in the C(Authorization) header.
      - Prefer the environment variable to writing the token in the configuration file.
    required: true
    type: str
    env:
      - name: CMDB_TOKEN
  validate_certs:
    description: Whether to check the CMDB's TLS certificate when O(url) is C(https).
    type: bool
    default: true
    env:
      - name: CMDB_VALIDATE_CERTS
  timeout:
    description: Seconds to wait for the CMDB before giving up.
    type: int
    default: 10
"""

EXAMPLES = r"""
# inventory/prod.cmdb.yml, with CMDB_TOKEN set in the environment
plugin: example.cmdb.cmdb
url: https://cmdb.example.com/api/servers

---
# The same, with groups per environment, ansible_host from the CMDB,
# and the inventory cache in a local directory
plugin: example.cmdb.cmdb
url: https://cmdb.example.com/api/servers
strict: true
compose:
  ansible_host: cmdb_address
keyed_groups:
  - key: cmdb_env
    prefix: env
cache: true
cache_plugin: ansible.builtin.jsonfile
cache_connection: ~/.cache/ansible/cmdb
"""

import json

from ansible.errors import AnsibleParserError
from ansible.module_utils.common.text.converters import to_native
from ansible.module_utils.urls import ConnectionError, open_url
from ansible.plugins.inventory import BaseInventoryPlugin, Cacheable, Constructable


class InventoryModule(BaseInventoryPlugin, Constructable, Cacheable):
    """Reads the CMDB's servers and adds them to the inventory."""

    NAME = "example.cmdb.cmdb"

    def verify_file(self, path: str) -> bool:
        """Accept only configuration files named ``*cmdb.yml`` or ``*cmdb.yaml``.

        :param path: the inventory source given to Ansible
        :return: whether this plugin should parse it
        """
        return super().verify_file(path) and path.endswith(("cmdb.yml", "cmdb.yaml"))

    def parse(self, inventory, loader, path: str, cache: bool = True) -> None:
        """Read the configuration, get the servers (from the cache or the CMDB) and fill the inventory.

        :param inventory: the inventory object to fill
        :param loader: Ansible's data loader
        :param path: the configuration file
        :param cache: false when Ansible was run with ``--flush-cache``
        :raises AnsibleParserError: when the CMDB can't be read or its answer is not what the plugin expects
        """
        super().parse(inventory, loader, path, cache)
        self._read_config_data(path)  # also sets up the cache plugin when cache: true

        # The cache pattern from the developer guide: read the cache unless it's off or being
        # refreshed (--flush-cache), and write it back whenever the CMDB was asked.
        cache_key = self.get_cache_key(path)
        use_cache = self.get_option("cache") and cache
        update_cache = self.get_option("cache") and not cache
        servers = None
        if use_cache:
            try:
                servers = self._cache[cache_key]
            except KeyError:
                update_cache = True
        if servers is None:
            servers = self._fetch_servers()
        if update_cache:
            self._cache[cache_key] = servers

        for server in servers:
            self._add_server(server)

    def _fetch_servers(self) -> list[dict]:
        """Ask the CMDB for its servers and check the shape of the answer.

        :raises AnsibleParserError: on a network or HTTP error, a non-JSON answer, or a missing field
        :return: the list of servers
        """
        url = self.get_option("url")
        if not self.get_option("token"):  # required only means set: an empty CMDB_TOKEN passes
            raise AnsibleParserError("no token for the CMDB: set CMDB_TOKEN, or token in the configuration file")
        try:
            response = open_url(
                url,
                headers={"Authorization": f"Bearer {self.get_option('token')}", "Accept": "application/json"},
                validate_certs=self.get_option("validate_certs"),
                timeout=self.get_option("timeout"),
            )
            data = json.load(response)
        except (ConnectionError, OSError) as e:  # urllib's HTTPError and URLError are OSErrors
            raise AnsibleParserError(f"cannot read the CMDB at {url}: {to_native(e)}") from e
        except ValueError as e:
            raise AnsibleParserError(f"the CMDB at {url} did not answer with JSON: {to_native(e)}") from e

        if not isinstance(data, dict) or not isinstance(data.get("servers"), list):
            raise AnsibleParserError(f"the CMDB at {url} answered without a 'servers' list")
        for index, server in enumerate(data["servers"]):
            missing = [key for key in ("name", "role") if not server.get(key)]
            if missing:
                raise AnsibleParserError(f"server #{index} from {url} has no {' or '.join(missing)}")
        return data["servers"]

    def _add_server(self, server: dict) -> None:
        """Add one server: host, role group, cmdb_* variables, then the constructed options.

        :param server: one item of the CMDB's ``servers`` list
        """
        host = server["name"]
        group = self.inventory.add_group(server["role"])
        self.inventory.add_host(host, group=group)
        host_vars = {f"cmdb_{key}": value for key, value in server.items() if key != "name"}
        for key, value in host_vars.items():
            self.inventory.set_variable(host, key, value)

        # compose first, so that groups and keyed_groups can use the composed variables
        strict = self.get_option("strict")
        self._set_composite_vars(self.get_option("compose"), host_vars, host, strict=strict)
        self._add_host_to_composed_groups(self.get_option("groups"), host_vars, host, strict=strict)
        self._add_host_to_keyed_groups(self.get_option("keyed_groups"), host_vars, host, strict=strict)
