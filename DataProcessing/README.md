# DataProcessing

[`data_processing.py`](data_processing.py) turns one patch snapshot (produced by
[`../WebScraping/main.py`](../WebScraping/main.py)) into a simple champion-pick recommendation.
Run directly, it's an interactive command-line tool; its scoring/selection logic
(`calcularPeso`, `top_champions`, `recommend_for_role`) is also unit-tested in
[`../tests/test_data_processing.py`](../tests/test_data_processing.py) and can be imported on its
own.

## Input

`champInfoVersionCSV.csv` — a `;`-separated CSV with **no header row**, one line per champion, in
this column order:

```
Name;Popularity;WR;Banrate;Main;Pentakills;Gold;Minions;Wards;Damage
```

This is a manual export of `WebScraping/champInfoVersion.xlsx` for the patch you want
recommendations for (Excel/LibreOffice: *Save as → CSV*, `;` as the field separator).

`champInfoVersion.xlsx` and `champInfoVersionCSV.csv` in this folder are a sample export kept for
reference/testing. That sample was scraped before `scrap_champ.py` was fixed to keep the Gold and
Damage columns, so those two fields are blank for every row in it (not fabricated values) —
harmless, since neither is part of the scoring formula below.

## What it does

1. **Scores every champion** with a fixed weighted formula (`calcularPeso`):

   ```python
   peso = WR + 0.6*Popularity + 0.4*Banrate + Main + 100*Pentakills + 0.5*Minions + 2*Wards
   ```

   Pentakills is weighted heavily (×100) because its raw value is a very small decimal
   (pentakills per game), so this brings it onto a comparable scale with the percentage-based
   stats — the weights overall are a heuristic, not a statistically fitted model. Gold and Damage
   are captured in the input data but aren't part of this formula.

2. **Prints the top 5 champions of the patch** by that score, across all roles.

3. **Asks for your draft context**, interactively via stdin:
   - the role you're picking for: `mid`, `top`, `jung`, `adc` or `supp` (re-prompted until valid,
     matched against a hardcoded roster list per role in the script — a champion not in that list
     for the chosen role won't be considered);
   - 9 already-picked champion names (both teams);
   - 10 already-banned champion names (both teams).

4. **Prints the top 3 available champions for that role**, excluding anything already
   picked/banned, ranked by the same weighted score.

## Running it

```bash
cd DataProcessing
python data_processing.py
```

You'll be prompted for the role, then for 9 picked-champion names (one per line) and 10
banned-champion names (one per line) — 19 prompts in total, matching a full draft
(5 picks + 5 bans per team, minus the pick you're about to make).

## Notes

- Champion names must match the lowercase strings the scraper stored (e.g. `"kai'sa"`,
  `"dr. mundo"`, `"nunu & willump"`) — check `champInfoVersionCSV.csv` for the exact spelling if a
  name doesn't match.
- The role rosters (`TOP`, `JUNGLE`, `MID`, `ADC`, `SUPPORT` at the top of the script) are a
  snapshot of the meta at the time the thesis was written and will need updating as champions'
  common roles shift.
