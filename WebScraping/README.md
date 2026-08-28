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
page (`URL_ESP`) and hand off to the corresponding `scrap_*` function.

## `main.py` + `scrap_champ.py`

For each champion, `scrap_champ.scrap_champ(url, champ, number_of_champ)`:

1. Loads the champion's page and reads four dropdown summary values (popularity, win rate, ban
   rate, pick rate as main role) plus pentakills, gold, CS/minions and wards from fixed page
   elements.
2. Parses the page's inline `<script>` tags for three embedded chart datasets
   (`graphFuncgraphDD5` = popularity history, `graphFuncgraphDD6` = win rate history,
   `graphFuncgraphDD7` = ban rate history) and decodes their JSON payloads.
3. Appends `[champ, popularity, wr, banrate, main, pentakills, minions, wards]` as a new row to
   `champInfoVersion.xlsx` (gold and damage are read but not currently saved to this row).
4. Writes that champion's popularity/win-rate/ban-rate history to its own workbook,
   `champsHistory/champInfoHistory<champ>.xlsx`.

`champInfoVersion.xlsx` is (re-)created with a sheet named after the current patch (e.g.
`"V12.6"`) at the start of `main.py` — update that literal for the patch you're scraping.

## `main_graphics.py` + `scrap_graphics.py`

Same per-champion scraping of the three history charts, but instead of one file per champion it
appends each champion as **a new column** in three shared workbooks — one for popularity, one for
win rate, one for ban rate — with dates as the first column. This is the layout the R analysis in
[`../RStudio/`](../RStudio/) expects (one time series per champion, aligned by date).

⚠️ These three combined workbooks are currently written to an **absolute path outside this
repository** — see the root [README's Setup section](../README.md#setup) before running this
script.

## `champ.py`

A small `Champ` class (name/winrate/banrate/pickrate). It isn't imported or used by any of the
scraping scripts — an early sketch kept for reference.

## Other files

- `champsHistory/` — one workbook per champion, produced by `main.py` (161 files as of the last
  scrape). Each has two columns: date and value, for popularity/WR/BR.
- `codigofuente.txt` — a raw saved HTML page kept from development/debugging; not read by any
  script.
- `filehtml.txt` — empty placeholder, unused.

## Notes on the target site

- The champion list is read from the **English** page (`URL`), but each champion's stats are then
  scraped from the **Spanish** page (`URL_ESP`) — the same page, different locale, is used
  because the URL-slug logic was built against the Spanish champion names.
- A handful of champion names don't match their URL slug and are patched manually in both
  `scrap_champ.py` and `scrap_graphics.py` (e.g. `"wukong"` → `"monkeyking"`, `"renata glasc"` →
  `"renata"`). If a champion's URL changes or a new champion needs a similar fix, add it to the
  same `.replace(...)` chain.
- `NUMBER_OF_CHAMPS` (in `main.py`/`main_graphics.py`) must be at least the number of champions
  currently on the site; it's a loop bound over dropdown list items, not a strict requirement.
