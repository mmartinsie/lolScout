# lolScout

lolScout collects *League of Legends* champion statistics from leagueofgraphs.com and turns them
into two things: a data-driven pick recommendation for the current patch, and a longer-term view
of how each champion's popularity, win rate and ban rate move across patches.

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
been collected over enough patches to form time series.

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

`requirements.txt` pins `selenium<4.3.0` because the scraping scripts use Selenium's legacy
`find_element_by_xpath(...)` API, removed in Selenium 4.3.

### 2. Point the scripts at your own machine

The scraping scripts were written for one specific machine and still contain hardcoded, absolute
Windows paths — update these before running them:

- **ChromeDriver path** — `webdriver.Chrome(executable_path='C:/WebDriver/bin/chromedriver.exe')`
  in [`main.py`](WebScraping/main.py), [`main_graphics.py`](WebScraping/main_graphics.py),
  [`scrap_champ.py`](WebScraping/scrap_champ.py) and [`scrap_graphics.py`](WebScraping/scrap_graphics.py).
- **Output paths** — [`scrap_champ.py`](WebScraping/scrap_champ.py) reads/writes
  `champInfoVersion.xlsx` and `champsHistory/*.xlsx` via absolute paths, and
  [`scrap_graphics.py`](WebScraping/scrap_graphics.py) writes the three combined history
  workbooks to a path **outside this repository**. Both need updating to a folder that exists on
  your machine.
- **Patch label** — the current patch is hardcoded as a sheet name (e.g. `"V12.6"`) in
  [`main.py`](WebScraping/main.py) and [`scrap_champ.py`](WebScraping/scrap_champ.py).
- **Champion count** — `NUMBER_OF_CHAMPS` in `main.py` / `main_graphics.py` must be at least the
  number of champions currently listed on the site.

See [WebScraping/README.md](WebScraping/README.md) for details on each script.

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

## Example output

A row of scraped, patch-snapshot data for one champion
(`DataProcessing/champInfoVersionCSV.csv`, `;`-separated — see
[DataProcessing/README.md](DataProcessing/README.md) for the full column list):

```
zed;12.3;49.4;40.2;1.4;0.0014;6.09;0.24
```

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
fixed `time.sleep(5)` after each page load gives the page's charts time to finish rendering
before BeautifulSoup parses the HTML. It's a simple, conservative throttle — one page at a time,
no concurrency — rather than protocol-level rate-limit handling, since there's no API contract
(rate-limit headers, request budget, backoff-and-retry) to honor in the first place. Moving to
the official Riot Games API, which does define per-key rate limits, would be a reasonable future
step, but it isn't what this project does today.

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
scraper and the R analysis scripts.

## Repository structure

| Path | Description |
|---|---|
| [`WebScraping/`](WebScraping/) | Selenium scrapers that pull champion stats and history graphs from leagueofgraphs.com. See [WebScraping/README.md](WebScraping/README.md). |
| [`DataProcessing/`](DataProcessing/) | Turns a patch snapshot CSV into a simple champion-picking recommendation. See [DataProcessing/README.md](DataProcessing/README.md). |
| [`RStudio/`](RStudio/) | Clustering and time-series forecasting of champion stats history. See [RStudio/README.md](RStudio/README.md). |
| [`docs/`](docs/) | Full text of both Bachelor's theses (PDF, Spanish). |
| [`otros/`](otros/) | A single extra copy of a champions CSV snapshot, kept for reference. |

## Known limitations

- Built against leagueofgraphs.com's markup and Spanish-locale URLs (`/es/...`) as of the 2021–2022
  thesis work; the site's layout, script variable names (`graphFuncgraphDD5/6/7`) and element
  XPaths may have changed since.
- Hardcoded, machine-specific absolute paths throughout — see
  [Getting started](#2-point-the-scripts-at-your-own-machine).
- Uses Selenium's pre-4.3 `find_element_by_xpath` API (see [Prerequisites](#prerequisites)).
- `scrap_champ.py` scrapes gold and damage stats but doesn't currently include them in the row it
  saves.
- No retry/error handling around the scraping — a missing element or a slow page load raises an
  unhandled exception and stops the run partway through the champion list.

## Disclaimer

This project was built for academic purposes to scrape publicly visible statistics pages. It
performs one page load per champion with a fixed delay between requests rather than concurrent or
aggressive scraping, but it comes with no guarantee of respecting leagueofgraphs.com's current
Terms of Service or `robots.txt` — review those yourself before running it, and use it
responsibly.

## License

[MIT](LICENSE) © 2022 Manuel Martín Sierra
