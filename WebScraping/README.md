# WebScraping

Selenium/BeautifulSoup scrapers that pull champion statistics from
[leagueofgraphs.com](https://www.leagueofgraphs.com/es/champions/stats/) for every champion in
the game. There are two independent pipelines, sharing the same champion-list discovery logic:

| Entry point | Worker | Produces |
|---|---|---|
| [`main.py`](main.py) | [`scrap_champ.py`](scrap_champ.py) | One row per champion for the **current patch**, plus one small history workbook per champion. |
| [`main_graphics.py`](main_graphics.py) | [`scrap_graphics.py`](scrap_graphics.py) | Three workbooks with **every champion's history** for one metric each (popularity, win rate, ban rate). |

Both entry points do the same first steps: open the English stats page (needed because the
champion list's XPath only resolves reliably there), click the champion filter dropdown, and
read the list of champion names to iterate over. They then visit each champion's Spanish-locale
page (`URL_ESP`) and hand off to the corresponding `scrap_*` function. A failure while scraping
one champion (a missing element, a slow page load) is caught and logged rather than aborting the
whole run; skipped champions are listed at the end.

## Configuration

Every path and setting these scripts use — the ChromeDriver location, the target URLs, the patch
label, the champion-count loop bound, output locations, the per-page delay — lives in
[`config.py`](config.py), with defaults that work out of the box and an environment-variable
override for each one. See that file for the full list. In particular:

- `CHROMEDRIVER_PATH` defaults to `chromedriver` on `PATH`; set it if your binary lives elsewhere.
- `LOLSCOUT_PATCH_VERSION` should be set to the patch you're scraping before each run — there's
  no reliable way to read it from the page.
- Output paths all default to folders inside `WebScraping/`; `LOLSCOUT_CHAMPS_HISTORY_GRAPHICS_DIR`
  used to point outside the repository entirely and no longer does by default.

## `main.py` + `scrap_champ.py`

For each champion, `scrap_champ.scrap_champ(url, champ, number_of_champ)`:

1. Loads the champion's page and reads four dropdown summary values (popularity, win rate, ban
   rate, pick rate as main role) plus pentakills, gold, CS/minions, wards and damage from fixed
   page elements.
2. Parses the page's inline `<script>` tags for three embedded chart datasets
   (`graphFuncgraphDD5` = popularity history, `graphFuncgraphDD6` = win rate history,
   `graphFuncgraphDD7` = ban rate history) and decodes their JSON payloads.
3. Appends `[champ, popularity, wr, banrate, main, pentakills, gold, minions, wards, damage]` as
   a new row to `champInfoVersion.xlsx`.
4. Writes that champion's popularity/win-rate/ban-rate history to its own workbook,
   `champsHistory/champInfoHistory<champ>.xlsx`.

`champInfoVersion.xlsx` is (re-)created with a sheet named after `config.PATCH_VERSION` at the
start of `main.py` — set that env var for the patch you're scraping.

Each call opens and always closes its own Chrome session (`try`/`finally`), so a failure partway
through one champion doesn't leak a browser process into the next one.

## `main_graphics.py` + `scrap_graphics.py`

Same per-champion scraping of the three history charts, but instead of one file per champion it
appends each champion as **a new column** in three shared workbooks — one for popularity, one for
win rate, one for ban rate — with dates as the first column. This is the layout the R analysis in
[`../RStudio/`](../RStudio/) expects (one time series per champion, aligned by date).

`scrap_graphics.py` reuses `scrap_champ.py`'s URL-slug and chart-parsing logic (`_slugify`,
`_read_chart_history`) rather than duplicating it.

## Other files

- `champsHistory/` — one workbook per champion, produced by `main.py` (161 files as of the last
  scrape). Each has two columns: date and value, for popularity/WR/BR.

## Notes on the target site

- The champion list is read from the **English** page (`config.URL`), but each champion's stats
  are then scraped from the **Spanish** page (`config.URL_ESP`) — the same page, different
  locale, is used because the URL-slug logic was built against the Spanish champion names.
- A handful of champion names don't match their URL slug and are patched manually in
  `scrap_champ.py`'s `_slugify()` (e.g. `"wukong"` → `"monkeyking"`, `"renata glasc"` →
  `"renata"`). If a champion's URL changes or a new champion needs a similar fix, add it there.
- `LOLSCOUT_NUMBER_OF_CHAMPS` must be at least the number of champions currently on the site; it's
  a loop bound over dropdown list items (indices beyond the real list are caught and skipped), not
  a strict requirement, so it defaults to a generously high value.
