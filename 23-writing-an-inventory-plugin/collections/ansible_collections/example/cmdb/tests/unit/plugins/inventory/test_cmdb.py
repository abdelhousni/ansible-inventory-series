"""Unit tests for the example.cmdb.cmdb inventory plugin, with the HTTP call mocked."""

from __future__ import annotations

import io
import json
import urllib.error
from unittest import mock

import pytest

from ansible.errors import AnsibleParserError
from ansible.inventory.data import InventoryData
from ansible.parsing.dataloader import DataLoader
from ansible.plugins.loader import inventory_loader

OPEN_URL = "ansible_collections.example.cmdb.plugins.inventory.cmdb.open_url"
URL = "https://cmdb.test/api/servers"
SERVERS = [
    {"name": "app1", "role": "app", "env": "prod", "owner": "web-team", "address": "10.0.1.11"},
    {"name": "db1", "role": "db", "env": "test", "owner": "dba-team", "address": "10.0.2.21"},
]


def answer(data):
    """A fake HTTP response holding ``data`` as JSON."""
    return io.BytesIO(json.dumps(data).encode())


@pytest.fixture(autouse=True)
def cmdb_env(monkeypatch):
    """The URL and the token come from the environment, as in run.sh."""
    monkeypatch.setenv("CMDB_URL", URL)
    monkeypatch.setenv("CMDB_TOKEN", "unit-test-token")


def write_config(tmp_path, text="plugin: example.cmdb.cmdb\n", name="hosts.cmdb.yml"):
    path = tmp_path / name
    path.write_text(text)
    return str(path)


def parse(config, cache=True):
    """Run the plugin on ``config`` and return the inventory it built."""
    plugin = inventory_loader.get("example.cmdb.cmdb")
    inventory = InventoryData()
    plugin.parse(inventory, DataLoader(), config, cache=cache)
    if plugin.get_option("cache"):
        plugin.update_cache_if_changed()  # what InventoryManager does after each parse
    return inventory


@pytest.mark.parametrize("name, expected", [("hosts.cmdb.yml", True), ("prod.cmdb.yaml", True), ("hosts.yml", False)])
def test_verify_file_checks_the_name(tmp_path, name, expected):
    plugin = inventory_loader.get("example.cmdb.cmdb")
    assert plugin.verify_file(write_config(tmp_path, name=name)) is expected


def test_hosts_groups_and_variables(tmp_path):
    with mock.patch(OPEN_URL, return_value=answer({"servers": SERVERS})) as open_url:
        inventory = parse(write_config(tmp_path))
    assert sorted(inventory.groups["app"].hosts, key=str) == [inventory.hosts["app1"]]
    assert inventory.hosts["db1"].vars["cmdb_owner"] == "dba-team"
    assert "cmdb_name" not in inventory.hosts["db1"].vars
    assert open_url.call_args.args == (URL,)
    assert open_url.call_args.kwargs["headers"]["Authorization"] == "Bearer unit-test-token"
    assert open_url.call_args.kwargs["validate_certs"] is True


def test_constructed_options(tmp_path):
    config = write_config(tmp_path, "plugin: example.cmdb.cmdb\nstrict: true\n"
                                    "compose:\n  ansible_host: cmdb_address\n"
                                    "keyed_groups:\n  - key: cmdb_env\n    prefix: env\n")
    with mock.patch(OPEN_URL, return_value=answer({"servers": SERVERS})):
        inventory = parse(config)
    assert [h.name for h in inventory.groups["env_prod"].hosts] == ["app1"]
    assert inventory.hosts["db1"].vars["ansible_host"] == "10.0.2.21"


@pytest.mark.parametrize("error, message", [
    (urllib.error.HTTPError(URL, 401, "Unauthorized", {}, None), "cannot read the CMDB at .*401"),
    (urllib.error.URLError("Connection refused"), "cannot read the CMDB at .*Connection refused"),
])
def test_network_errors(tmp_path, error, message):
    with mock.patch(OPEN_URL, side_effect=error), pytest.raises(AnsibleParserError, match=message):
        parse(write_config(tmp_path))


@pytest.mark.parametrize("body, message", [
    (io.BytesIO(b"<html>Please log in</html>"), "did not answer with JSON"),
    (answer({"hosts": SERVERS}), "without a 'servers' list"),
    (answer({"servers": [{"role": "app"}]}), "server #0 .* has no name"),
    (answer({"servers": [{"name": "x"}]}), "server #0 .* has no role"),
])
def test_unexpected_answers(tmp_path, body, message):
    with mock.patch(OPEN_URL, return_value=body), pytest.raises(AnsibleParserError, match=message):
        parse(write_config(tmp_path))


def test_empty_token(tmp_path, monkeypatch):
    monkeypatch.setenv("CMDB_TOKEN", "")
    with mock.patch(OPEN_URL) as open_url, pytest.raises(AnsibleParserError, match="no token for the CMDB"):
        parse(write_config(tmp_path))
    open_url.assert_not_called()


def test_missing_token(tmp_path, monkeypatch):
    monkeypatch.delenv("CMDB_TOKEN")
    with mock.patch(OPEN_URL) as open_url, pytest.raises(Exception, match="token"):
        parse(write_config(tmp_path))
    open_url.assert_not_called()


def test_cache_then_flush(tmp_path):
    config = write_config(tmp_path, "plugin: example.cmdb.cmdb\ncache: true\n"
                                    f"cache_plugin: ansible.builtin.jsonfile\ncache_connection: {tmp_path}/cache\n")
    changed = [dict(SERVERS[0], name="app9")]
    with mock.patch(OPEN_URL, side_effect=[answer({"servers": SERVERS}), answer({"servers": changed})]) as open_url:
        assert "db1" in parse(config).hosts  # cache empty: the CMDB is asked
        assert "db1" in parse(config).hosts  # from the cache: not asked
        assert open_url.call_count == 1
        assert list(parse(config, cache=False).hosts) == ["app9"]  # --flush-cache: asked again
        assert open_url.call_count == 2
