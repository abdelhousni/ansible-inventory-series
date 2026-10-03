"""Lets plain pytest import the collection; ansible-test units sets this up itself."""

from __future__ import annotations

import pathlib

from ansible.plugins.loader import init_plugin_loader
from ansible.utils.collection_loader import AnsibleCollectionConfig

if not AnsibleCollectionConfig.collection_finder:
    # tests/unit/conftest.py -> the directory that holds ansible_collections/
    init_plugin_loader([str(pathlib.Path(__file__).resolve().parents[5])])
