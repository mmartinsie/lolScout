# RStudio — time-series analysis

R scripts that analyse how champion statistics evolve across patches: they group champions with
similar behaviour over time (clustering) and then forecast where each group's win rate / ban rate
is headed (multiple forecasting models compared against each other). This is the core analysis of
the underlying thesis, *"Análisis y predicción de series temporales aplicados al videojuego
League of Legends"*.

| Script | Metric analysed |
|---|---|
| [`TFG.R`](TFG.R) | Win rate |
| [`TFG-BR.R`](TFG-BR.R) | Ban rate |

Both scripts follow the same structure and only differ in which combined history workbook they
expect as input.

## Input

A combined history workbook produced by
[`../WebScraping/main_graphics.py`](../WebScraping/main_graphics.py) — one sheet, one column per
champion, one row per patch/date (`champInfoWRComplete.xlsx` for `TFG.R`,
`champInfoBRComplete.xlsx` for `TFG-BR.R`). `champs_information.csv` in this folder is a flattened
CSV export in the same spirit, kept as a reference sample.

Running either script opens a **file picker** (`file.choose()`) — point it at the workbook, and
the script derives its working directory from the chosen file's path.

## Required R packages

Both scripts now only install a package if it isn't already available
(`requireNamespace(pkg, quietly = TRUE)`), instead of unconditionally reinstalling every package
on every run:

```r
required_packages <- c("Rcpp", "readxl", "e1071", "imputeTS", "cluster", "pdc", "TSclust",
                        "MASS", "forecast", "tsfknn", "rnn", "ForecastComb", "xts", "dygraphs",
                        "ape")
```

`dplyr`/`tidyverse` are used in a couple of places further down but aren't part of that
install-guard list; install them separately if a `dplyr`-related error comes up.

## ARNN.R

`TFG.R` also `source()`s an auxiliary script, `ARNN.R`, for the autoregressive neural network
forecasting method — from a hardcoded absolute path outside this repository, so it doesn't run
out of the box. That file is a genuine dependency, not a placeholder: it's the R implementation
of the `arnn` package used for the ARNN forecasting method (method 3 in the pipeline below), and
it comes from **Carlos Arias Alcaide**'s Master's thesis at Universidad Rey Juan Carlos,
*"Análisis avanzado y predicción de series temporales aplicados en un caso de Business
Analytics"* (Máster en Ingeniería de Sistemas de la Decisión, 2020–2021) — supervised by the same
tutors as the Mathematics thesis behind this repo. `TFG.R`'s overall structure (the
`file.choose()` + working-directory setup, the function layout) was modelled on that thesis'
accompanying code.

`ARNN.R` isn't included in this repository. To run `TFG.R` end to end you'll need to either
obtain that script (with its author's permission, since it isn't this project's code to
redistribute) or supply your own equivalent autoregressive-NN forecasting function under the same
name.

## Pipeline

1. **Load & impute** — reads the workbook as a multi-column time series (`ts`), replaces `0`
   values with `NA` (a champion with no recorded stat that patch, not an actual zero) and fills
   gaps with linear interpolation (`imputeTS::na_interpolation`).
2. **Standardise** the series (`scale()`) so champions with very different popularity aren't
   dominated by magnitude when computing distances.
3. **Cluster champions** by similarity of behaviour over time, comparing four distance metrics
   (`TSclust::diss`):
   - `EUCL` — Euclidean (proximity of values)
   - `COR` — correlation (shape of the curve)
   - `DTWARP` — Dynamic Time Warping (shape, tolerant to time shifts)
   - `CORT` — a combination of proximity and behaviour (the one the thesis settles on)

   ...crossed with five linkage methods (single, ward.D, average, centroid, complete),
   visualised as dendrograms and 2D multidimensional-scaling plots exported as PDF/PNG. The
   script settles on **`CORT` distance + `ward.D` linkage, 5 clusters** as the final choice
   (`tipo_distancia`, `encadenamiento`, `n_clusteres`), based on the analysis in the thesis.
4. **Pick a representative champion per cluster** — the champion whose series is closest to that
   cluster's mean series — to keep the forecasting step below to a manageable, representative
   subset instead of running six models over every champion.
5. **Forecast each representative's future values** with six approaches, each compared by RMSE
   (`ECM`) and MAE (`EAM`) on a held-out test window:
   1. **SARIMA** (`forecast::auto.arima`)
   2. **TBATS** (`forecast::tbats`)
   3. **ARNN** — autoregressive neural network (via `ARNN.R`, see above)
   4. **k-NN** — both recursive and MIMO strategies (`tsfknn`)
   5. **SVM** — support vector regression (`e1071`)
   6. **Forecast combination** — arithmetic mean, inverse-variance weighting, and CLS
      (constrained least squares) ensembles of the above (`ForecastComb`)
6. **Plot** actual vs. predicted series per champion (`dygraphs`, interactive) for visual
   inspection of forecast quality.

## Known limitations

- `ARNN.R` still needs to be sourced from outside this repository — see [above](#arnnr).
- Champion names in plot titles/examples near the end of each script are hardcoded (e.g. `jayce`,
  `morgana`) as illustrative examples from the thesis, not a general-purpose report generator.
