# lolScout

lolScout collects *League of Legends* champion statistics from leagueofgraphs.com and turns them
into two things: a data-driven pick recommendation for the current patch, and a longer-term view
of how each champion's popularity, win rate and ban rate move across patches.

**[Try the pick recommender in your browser →](https://mmartinsie.github.io/lolScout/)** — a
static demo (see [Live demo](#live-demo)) that runs the same scoring logic client-side against a
bundled sample snapshot; no scraping happens from that page.

## Context

lolScout is the code behind two Bachelor's theses completed at Universidad Rey Juan Carlos
(Spain) in the 2021–2022 academic year, where the author holds two separate degrees — a BSc in
Computer Science and a BSc in Mathematics — each looking at the same data from a different angle:

- **BSc in Computer Science** —
  [*Analysis and Modelling of Game Data from League of Legends Patch 12.7*](docs/bsc-thesis-computer-science-lol-data-modelling.pdf)
  (full text in Spanish). The engineering side: scraping and structuring a patch snapshot of
  champion data, and building the weighted scoring model behind the pick recommender.
- **BSc in Mathematics** —
  [*Time Series Analysis and Forecasting Applied to League of Legends*](docs/bsc-thesis-mathematics-lol-time-series.pdf)
  (full text in Spanish). The statistical side: clustering champions by how their stats behave
  over time, and comparing several forecasting models to predict where those stats are headed.

The two are complementary: the Computer Science thesis is what gets the data out of the website
and into a usable shape; the Mathematics thesis is what that data is analysed with once it's
been collected over enough patches to form time series. Both PDFs are the full, original thesis
text and are copyrighted by the author — see [License](#license) for what that does and doesn't
cover.

## How it works

```
leagueofgraphs.com (stats page, per champion)
        │
        ▼
WebScraping/ (Selenium + BeautifulSoup)
  ├─ main.py + scrap_champ.py     → one row per champion, current patch
  │                                  → WebScraping/champInfoVersion.xlsx
  │                                  → WebScraping/champsHistory/champInfoHistory<champ>.xlsx
  │
  └─ main_graphics.py + scrap_graphics.py
                                   → per-metric history across ALL champions
                                     (popularity / win rate / ban rate, one workbook each)
        │
        ├──────────────────────────────┐
        ▼                               ▼
DataProcessing/data_processing.py   RStudio/ (TFG.R, TFG-BR.R)
  → weighted score per champion       → clustering champions by time-series behaviour
  → top-5 champions of the patch      → SARIMA / TBATS / ARNN / KNN / SVM / ensemble
  → best pick for a role, given         forecasts of future win rate & ban rate
    already picked/banned champions
```

## Live demo

**https://mmartinsie.github.io/lolScout/** — a static site (in [`docs/`](docs/), served by
GitHub Pages) with two things you can try without installing anything:

- The **pick recommender**, running in your browser: pick a role and tick off already
  picked/banned champions, and it scores every champion with the exact same formula as
  [`DataProcessing/data_processing.py`](DataProcessing/data_processing.py) — ported to
  JavaScript ([`docs/app.js`](docs/app.js)) and run entirely client-side against the bundled
  sample snapshot. No scraping happens from that page.
- A handful of **pre-generated results** from the time-series analysis (win/ban/pick-rate charts
  and two per-champion win-rate series) as a sample of what [`RStudio/`](RStudio/) produces —
  static images, not recalculated on the page (that needs a full R environment).

The Pages site isn't enabled automatically on a fork — turn it on under *Settings → Pages →
Deploy from a branch → `master` / `/docs`*. See [`docs/README.md`](docs/README.md) for how the
demo is put together and how to refresh its sample data.

## Getting started

### Prerequisites

- Python 3.9+
- [Google Chrome](https://www.google.com/chrome/) and a matching
  [ChromeDriver](https://chromedriver.chromium.org/) binary
- R 4.x with RStudio, only if you want to run the time-series analysis in [`RStudio/`](RStudio/)

### 1. Clone and install dependencies

```bash
git clone <this-repository-url>
cd lolScout
pip install -r requirements.txt
```

### 2. Configure the scraper

Every path and setting the scraper needs lives in [`WebScraping/config.py`](WebScraping/config.py)
with defaults that work out of the box (ChromeDriver on `PATH`, outputs written inside the repo),
and every one of them can be overridden with an environment variable instead of editing code:

```bash
export CHROMEDRIVER_PATH=/usr/local/bin/chromedriver   # if it's not on PATH
export LOLSCOUT_PATCH_VERSION=V14.1                     # the patch you're scraping
```

See [`config.py`](WebScraping/config.py) for the full list of variables (output locations, the
target URLs, the champion-count loop bound, the per-page delay).

### 3. Run it

```bash
# Scrape a patch snapshot (one row per champion + one history workbook per champion)
cd WebScraping
python main.py

# Scrape combined history graphs (needed for the R analysis)
python main_graphics.py

# Get a pick recommendation for the current patch
# (first export champInfoVersion.xlsx to DataProcessing/champInfoVersionCSV.csv, ';'-separated)
cd ../DataProcessing
python data_processing.py
```

For the time-series analysis, open [`RStudio/TFG.R`](RStudio/TFG.R) (win rate) or
[`RStudio/TFG-BR.R`](RStudio/TFG-BR.R) (ban rate) in RStudio and source it — it will prompt you
to pick the combined history workbook produced by `main_graphics.py`. See
[RStudio/README.md](RStudio/README.md) for the required R packages and the analysis pipeline.

### Running the tests

```bash
pip install -r requirements.txt -r requirements-dev.txt
pytest
```

The suite (in [`tests/`](tests/)) covers the scoring/recommendation logic in
[`DataProcessing/data_processing.py`](DataProcessing/data_processing.py) and the configuration
defaults in [`WebScraping/config.py`](WebScraping/config.py) — it doesn't launch a browser or
hit the network, so it runs without Chrome/ChromeDriver installed. It also runs in CI on every
push (see [`.github/workflows/ci.yml`](.github/workflows/ci.yml)).

## Example output

A row of scraped, patch-snapshot data for one champion
(`DataProcessing/champInfoVersionCSV.csv`, `;`-separated — see
[DataProcessing/README.md](DataProcessing/README.md) for the full column list):

```
zed;12.3;49.4;40.2;1.4;0.0014;;6.09;0.24;
```

(The two empty fields are Gold and Damage — this particular sample predates the fix that makes
`scrap_champ.py` keep those columns; see [Design notes](#design-notes).)

Running the recommender on that snapshot:

```
$ python data_processing.py
Los cinco mejores campeones de la version son
 1) zed
 2) lucian
 3) samira
 4) ahri
 5) yasuo
Posición elegida (mid,top,jung,adc,supp):
mid
Nombre de los 9 campeones elegidos por ambos equipos:
[... 9 champion names, one per line ...]
Nombre de los 10 campeones baneados por ambos equipos:
[... 10 champion names, one per line ...]
Las tres mejores elecciones para la posición mid son
 1) yone
 2) katarina
 3) vex
```

The scores and prompts above are genuine output from the script (run against the sample CSV
included in the repo); the console text itself is Spanish, matching the rest of the script's
user-facing strings.

## Design notes

**Request throttling.** There is no Riot Games API call anywhere in this codebase — the scraper
talks to leagueofgraphs.com's public stats pages through a real Chrome browser driven by
Selenium. Each champion is scraped in its own browser session
(`webdriver.Chrome(...)` created per champion in `scrap_champ.py` / `scrap_graphics.py`), and a
fixed delay after each page load (`PAGE_LOAD_DELAY` in `config.py`, 5 seconds by default) gives
the page's charts time to finish rendering before BeautifulSoup parses the HTML. It's a simple,
conservative throttle — one page at a time, no concurrency — rather than protocol-level
rate-limit handling, since there's no API contract (rate-limit headers, request budget,
backoff-and-retry) to honor in the first place. Moving to the official Riot Games API, which does
define per-key rate limits, would be a reasonable future step, but it isn't what this project
does today. A failure on any one champion (a missing element, a slow page) is now caught and
logged rather than aborting the whole run — see `main.py` / `main_graphics.py`.

**Data storage and structure.** Data is kept in Excel workbooks (`.xlsx`, via `openpyxl` /
`xlsxwriter`) rather than a database, in three shapes:

- one **snapshot** workbook, one row per champion, current patch
  (`champInfoVersion.xlsx`);
- one **per-champion history** workbook, long format, one row per patch
  (`champsHistory/champInfoHistory<champion>.xlsx`);
- three **combined history** workbooks, one per metric (popularity / win rate / ban rate), wide
  format with one column per champion and one row per patch — the exact shape the R side needs to
  build a multivariate time series (`ts` object) with one series per champion.

Excel was a practical choice for a two-person, two-thesis project: it's easy to inspect by hand
while iterating on the scraper, needs no server or schema migration, and both sides consume it
natively (`pandas`/`openpyxl` on the Python side, `readxl` on the R side). `;`-separated CSV
exports are used as the hand-off format into `pandas` and as flattened reference samples, since a
manual "save as CSV" step was simpler than building a shared data layer between the Python
scraper and the R analysis scripts. One concrete fix worth calling out: `scrap_champ.py` used to
scrape gold and damage per champion and then silently drop both from the saved row; they're now
kept, so a snapshot row is `Name, Popularity, WR, Banrate, Main, Pentakills, Gold, Minions, Wards,
Damage` — matching what `RStudio/`'s scripts expected all along. The bundled sample CSV was
scraped before this fix, so its Gold/Damage fields are blank (not fabricated) rather than
backfilled.

**Configuration.** Every hardcoded, machine-specific path this project used to have (ChromeDriver
location, output workbook paths, a folder that pointed outside the repository entirely) now lives
in [`WebScraping/config.py`](WebScraping/config.py) with a repo-relative default and an
environment-variable override — see [Getting started](#2-configure-the-scraper).

## Repository structure

| Path | Description |
|---|---|
| [`WebScraping/`](WebScraping/) | Selenium scrapers that pull champion stats and history graphs from leagueofgraphs.com. See [WebScraping/README.md](WebScraping/README.md). |
| [`DataProcessing/`](DataProcessing/) | Turns a patch snapshot CSV into a simple champion-picking recommendation. See [DataProcessing/README.md](DataProcessing/README.md). |
| [`RStudio/`](RStudio/) | Clustering and time-series forecasting of champion stats history. See [RStudio/README.md](RStudio/README.md). |
| [`tests/`](tests/) | Pytest suite for the scoring logic and the scraper configuration; runs in CI (`.github/workflows/ci.yml`). |
| [`docs/`](docs/) | Full text of both Bachelor's theses (PDF, Spanish), plus the [live demo](#live-demo) GitHub Pages site. See [docs/README.md](docs/README.md). |
| [`otros/`](otros/) | A single extra copy of a champions CSV snapshot, kept for reference. |

## Known limitations

- Built against leagueofgraphs.com's markup and Spanish-locale URLs (`/es/...`) as of the 2021–2022
  thesis work; the site's layout, script variable names (`graphFuncgraphDD5/6/7`) and element
  XPaths may have changed since.
- There's no reliable way to read the current patch number or champion count from the site, so
  `LOLSCOUT_PATCH_VERSION` and (to a lesser extent, since the loop already tolerates missing
  indices) `LOLSCOUT_NUMBER_OF_CHAMPS` still need to be set per run — see `config.py`.
- Champion-name-to-URL-slug conversion is a small manual patch list in `scrap_champ.py`
  (`_slugify`) for the handful of champions whose URL doesn't match their display name; a new
  champion needing the same treatment has to be added there by hand.
- `RStudio/TFG.R` still `source()`s an auxiliary script, `ARNN.R`, from a path outside this
  repository — see [RStudio/README.md](RStudio/README.md#arnnr) for where it comes from and what
  that means for running the script.

## Disclaimer

This project was built for academic purposes to scrape publicly visible statistics pages. It
performs one page load per champion with a fixed delay between requests rather than concurrent or
aggressive scraping, but it comes with no guarantee of respecting leagueofgraphs.com's current
Terms of Service or `robots.txt` — review those yourself before running it, and use it
responsibly.

## License

The code in this repository is [MIT](LICENSE) © 2022 Manuel Martín Sierra. That license does
**not** extend to the two thesis PDFs in [`docs/`](docs/) — that's academic writing, kept here as
reference material and © the author, all rights reserved, independent of the code's license.
