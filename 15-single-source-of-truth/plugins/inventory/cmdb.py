"""A minimal inventory plugin for the example's mock CMDB. An illustration, not a product."""

from __future__ import annotations

DOCUMENTATION = r"""
name: cmdb
short_description: Hosts from the example's mock CMDB
description:
  - Reads a JSON list of servers from O(url), puts each server in a group named after its role,
    and sets its owner as C(cmdb_owner).
  - The configuration file name must end with C(cmdb.yml) or C(cmdb.yaml).
extends_documentation_fragment:
  - inventory_cache
options:
  plugin:
    description: The name of this plugin.
    required: true
    choices: [cmdb]
  url:
    description: The URL of the CMDB's JSON list of servers.
    required: true
    type: str
"""

import json
import urllib.request

from ansible.errors import AnsibleParserError
from ansible.plugins.inventory import BaseInventoryPlugin, Cacheable


class InventoryModule(BaseInventoryPlugin, Cacheable):

    NAME = "cmdb"

    def verify_file(self, path):
        return super().verify_file(path) and path.endswith(("cmdb.yml", "cmdb.yaml"))

    def parse(self, inventory, loader, path, cache=True):
        super().parse(inventory, loader, path, cache)
        self._read_config_data(path)  # also loads the cache plugin when cache: true

        # The pattern from the developer guide: read the cache unless it's off or being
        # refreshed (--flush-cache), and write it back when the CMDB was asked.
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
            servers = self._fetch(self.get_option("url"))
        if update_cache:
            self._cache[cache_key] = servers

        for server in servers:
            self.inventory.add_group(server["role"])
            self.inventory.add_host(server["name"], group=server["role"])
            self.inventory.set_variable(server["name"], "cmdb_owner", server["owner"])

    @staticmethod
    def _fetch(url):
        try:
            with urllib.request.urlopen(url, timeout=5) as response:
                return json.load(response)["servers"]
        except OSError as e:
            raise AnsibleParserError(f"cannot read the CMDB at {url}: {e}") from e
