"""Repo-root pytest config: makes the standalone scripts in DataProcessing/ and
WebScraping/ importable as plain modules from tests/, without turning them into
installable packages."""
import os
import sys

ROOT = os.path.dirname(os.path.abspath(__file__))
for _module_dir in ("DataProcessing", "WebScraping"):
    _path = os.path.join(ROOT, _module_dir)
    if _path not in sys.path:
        sys.path.insert(0, _path)
