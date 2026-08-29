"""Tests for WebScraping/config.py: defaults must resolve inside the repo, and every
setting must be overridable through its environment variable."""
import importlib
import os

ENV_VARS = [
    "CHROMEDRIVER_PATH", "LOLSCOUT_URL_EN", "LOLSCOUT_URL_ES", "LOLSCOUT_PATCH_VERSION",
    "LOLSCOUT_NUMBER_OF_CHAMPS", "LOLSCOUT_PAGE_LOAD_DELAY", "LOLSCOUT_SNAPSHOT_WORKBOOK",
    "LOLSCOUT_CHAMPS_HISTORY_DIR", "LOLSCOUT_CHAMPS_HISTORY_GRAPHICS_DIR",
]


def _reload_config_without_env(monkeypatch):
    for var in ENV_VARS:
        monkeypatch.delenv(var, raising=False)
    import config
    return importlib.reload(config)


def test_default_output_paths_live_inside_the_repo(monkeypatch):
    config = _reload_config_without_env(monkeypatch)

    assert config.SNAPSHOT_WORKBOOK.startswith(config.BASE_DIR)
    assert config.CHAMPS_HISTORY_DIR.startswith(config.BASE_DIR)
    # This one used to default to a path outside the repository entirely.
    assert config.CHAMPS_HISTORY_GRAPHICS_DIR.startswith(config.BASE_DIR)


def test_settings_are_overridable_via_environment_variables(monkeypatch):
    monkeypatch.setenv("LOLSCOUT_PATCH_VERSION", "V99.9")
    monkeypatch.setenv("LOLSCOUT_NUMBER_OF_CHAMPS", "5")
    monkeypatch.setenv("CHROMEDRIVER_PATH", "/opt/chromedriver")

    import config
    importlib.reload(config)

    assert config.PATCH_VERSION == "V99.9"
    assert config.NUMBER_OF_CHAMPS == 5
    assert config.CHROMEDRIVER_PATH == "/opt/chromedriver"

    # Leave a clean module state for any test that runs after this one.
    for var in ("LOLSCOUT_PATCH_VERSION", "LOLSCOUT_NUMBER_OF_CHAMPS", "CHROMEDRIVER_PATH"):
        monkeypatch.delenv(var, raising=False)
    importlib.reload(config)


def test_ensure_output_dirs_creates_missing_directories(tmp_path, monkeypatch):
    monkeypatch.setenv("LOLSCOUT_CHAMPS_HISTORY_DIR", str(tmp_path / "history"))
    monkeypatch.setenv("LOLSCOUT_CHAMPS_HISTORY_GRAPHICS_DIR", str(tmp_path / "graphics"))

    import config
    importlib.reload(config)
    config.ensure_output_dirs()

    assert os.path.isdir(tmp_path / "history")
    assert os.path.isdir(tmp_path / "graphics")

    monkeypatch.delenv("LOLSCOUT_CHAMPS_HISTORY_DIR", raising=False)
    monkeypatch.delenv("LOLSCOUT_CHAMPS_HISTORY_GRAPHICS_DIR", raising=False)
    importlib.reload(config)
