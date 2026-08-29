"""Centralized, environment-overridable configuration for the WebScraping module.

Every script in this folder used to hardcode absolute, machine-specific paths (a
ChromeDriver location, output workbook paths, even a folder outside this repository).
That meant nothing here ran on a fresh clone without hand-editing several files first.

This module fixes that: every setting below has a sensible default relative to this
repository, and every one of them can be overridden with an environment variable
instead of editing code, e.g.:

    CHROMEDRIVER_PATH=/usr/local/bin/chromedriver LOLSCOUT_PATCH_VERSION=V14.1 python main.py
"""
import os

# Directory this file lives in (WebScraping/); every relative default below is anchored here.
BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# --- Selenium ------------------------------------------------------------------------
# Path (or bare command) to the ChromeDriver executable. Defaults to "chromedriver" so it
# works out of the box if it's on PATH; set CHROMEDRIVER_PATH to point at a specific binary.
CHROMEDRIVER_PATH = os.environ.get("CHROMEDRIVER_PATH", "chromedriver")

# Seconds to wait after each page load before reading it, so the page's charts have time
# to render before BeautifulSoup parses the HTML.
PAGE_LOAD_DELAY = float(os.environ.get("LOLSCOUT_PAGE_LOAD_DELAY", "5"))

# --- Target site ------------------------------------------------------------------------
# The champion list is read from the English page (the XPath was built against it); each
# champion's stats are then scraped from the Spanish page (the URL-slug logic was built
# against Spanish champion names). See WebScraping/README.md for details.
URL = os.environ.get("LOLSCOUT_URL_EN", "https://www.leagueofgraphs.com/en/champions/stats/")
URL_ESP = os.environ.get("LOLSCOUT_URL_ES", "https://www.leagueofgraphs.com/es/champions/stats/")

# --- Patch metadata -----------------------------------------------------------------
# Sheet name used for the current patch's snapshot. There is no reliable way to read the
# current patch number from the page, so this must be set per run; the placeholder below
# is intentionally not a real patch number, so it's obvious it needs overriding.
PATCH_VERSION = os.environ.get("LOLSCOUT_PATCH_VERSION", "current-patch")

# Loop bound when reading the champion dropdown list. It only needs to be *at least* the
# number of champions currently on the site — the loop already tolerates missing indices
# (a champion at an index beyond the real list simply raises and is skipped) — so this
# defaults to a generously high, safe upper bound rather than an exact, easily-stale count.
NUMBER_OF_CHAMPS = int(os.environ.get("LOLSCOUT_NUMBER_OF_CHAMPS", "200"))

# --- Output locations -----------------------------------------------------------------
# Snapshot workbook: one row per champion for the current patch (main.py / scrap_champ.py).
SNAPSHOT_WORKBOOK = os.environ.get(
    "LOLSCOUT_SNAPSHOT_WORKBOOK", os.path.join(BASE_DIR, "champInfoVersion.xlsx")
)

# One workbook per champion, history over time (main.py / scrap_champ.py).
CHAMPS_HISTORY_DIR = os.environ.get(
    "LOLSCOUT_CHAMPS_HISTORY_DIR", os.path.join(BASE_DIR, "champsHistory")
)

# Combined per-metric history workbooks, one column per champion (main_graphics.py /
# scrap_graphics.py) — this is what the R analysis in RStudio/ reads. Previously this
# pointed outside the repository entirely; it now defaults to a folder inside WebScraping/.
CHAMPS_HISTORY_GRAPHICS_DIR = os.environ.get(
    "LOLSCOUT_CHAMPS_HISTORY_GRAPHICS_DIR", os.path.join(BASE_DIR, "champsHistoryGraphics")
)
POP_HISTORY_WORKBOOK = os.path.join(CHAMPS_HISTORY_GRAPHICS_DIR, "champInfoPopComplete.xlsx")
WR_HISTORY_WORKBOOK = os.path.join(CHAMPS_HISTORY_GRAPHICS_DIR, "champInfoWRComplete.xlsx")
BR_HISTORY_WORKBOOK = os.path.join(CHAMPS_HISTORY_GRAPHICS_DIR, "champInfoBRComplete.xlsx")


def ensure_output_dirs():
    """Create the output directories this module writes to, if they don't exist yet."""
    os.makedirs(CHAMPS_HISTORY_DIR, exist_ok=True)
    os.makedirs(CHAMPS_HISTORY_GRAPHICS_DIR, exist_ok=True)
