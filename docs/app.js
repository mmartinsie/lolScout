// Client-side port of DataProcessing/data_processing.py's scoring logic. This is the
// same weighted formula and the same role rosters as the Python script — kept in sync by
// hand, since there's no build step here that could share one source of truth between a
// Python script and a static site. If you change the formula or a roster in
// data_processing.py, mirror the change here too.
//
// It runs entirely in the browser against the bundled sample snapshot in data/ — no
// server, no live scraping.

const HEADERS = ["Name", "Popularity", "WR", "Banrate", "Main", "Pentakills", "Gold",
  "Minions", "Wards", "Damage"];

const ROLE_ROSTERS = {
  top: ["aatrox", "camille", "cho'gath", "darius", "dr. mundo", "fiora", "gangplank", "garen",
    "gnar", "gwen", "illaoi", "irelia", "jax", "jayce", "kayle", "kennen", "kled", "malphite",
    "maokai", "mordekaiser", "nasus", "ornn", "pantheon", "poppy", "quinn", "renekton", "riven",
    "rumble", "sett", "shen", "singed", "sion", "tahm kench", "teemo", "trundle", "tryndamere",
    "urgot", "yorick"],
  jung: ["amumu", "diana", "ekko", "elise", "evelynn", "fiddlesticks", "gragas", "graves",
    "hecarim", "ivern", "jarvan iv", "karthus", "kayn", "kha'zix", "kindred", "lee sin",
    "lillia", "master yi", "nidalee", "nocturne", "nunu & willump", "olaf", "rammus",
    "rek'sai", "rengar", "sejuani", "shaco", "shyvana", "skarner", "taliyah", "talon",
    "udyr", "vi", "viego", "volibear", "warwick", "wukong", "xin zhao", "zac"],
  mid: ["ahri", "akali", "akshan", "anivia", "annie", "aurelion sol", "azir", "cassiopeia",
    "corki", "fizz", "galio", "heimerdinger", "kassadin", "katarina", "leblanc", "lissandra",
    "malzahar", "neeko", "orianna", "qiyana", "ryze", "sylas", "syndra", "twisted fate",
    "veigar", "vex", "viktor", "vladimir", "xerath", "yasuo", "yone", "zed", "ziggs", "zoe"],
  adc: ["aphelios", "ashe", "caitlyn", "draven", "ezreal", "jhin", "jinx", "kai'sa", "kalista",
    "kog'maw", "lucian", "miss fortune", "samira", "sivir", "tristana", "twitch", "varus",
    "vayne", "xayah", "zeri"],
  supp: ["alistar", "bard", "blitzcrank", "brand", "braum", "janna", "karma", "leona", "lulu",
    "lux", "morgana", "nami", "nautilus", "pyke", "rakan", "rell", "renata glasc", "senna",
    "seraphine", "sona", "soraka", "swain", "taric", "thresh", "vel'koz", "yuumi",
    "zilean", "zyra"],
};

/** Same weighted formula as calcularPeso() in DataProcessing/data_processing.py. */
function calcularPeso(row) {
  return (
    row.WR + 0.6 * row.Popularity + 0.4 * row.Banrate + row.Main
    + 100 * row.Pentakills + 0.5 * row.Minions + 2 * row.Wards
  );
}

/** Parses the bundled ';'-separated, headerless snapshot CSV into an array of row objects. */
function parseSnapshot(csvText) {
  return csvText
    .replace(/^﻿/, '') // strip a leading UTF-8 BOM, same as the sample file has
    .trim()
    .split('\n')
    .map((line) => {
      const fields = line.split(';');
      const row = {};
      HEADERS.forEach((header, i) => {
        const raw = (fields[i] || '').trim();
        row[header] = header === 'Name' ? raw : (raw === '' ? NaN : Number(raw));
      });
      row.Peso = calcularPeso(row);
      return row;
    });
}

/** Top-n champion names by score, optionally restricted to a roster and/or excluding names. */
function topChampions(rows, n, { roster = null, exclude = [] } = {}) {
  const excludeSet = new Set(exclude.map((name) => name.toLowerCase()));
  return rows
    .filter((row) => !roster || roster.includes(row.Name))
    .filter((row) => !excludeSet.has(row.Name.toLowerCase()))
    .sort((a, b) => b.Peso - a.Peso)
    .slice(0, n)
    .map((row) => row.Name);
}

function recommendForRole(rows, role, bannedAndPicked, n = 3) {
  const roster = ROLE_ROSTERS[role];
  if (!roster) throw new Error(`Unknown role: ${role}`);
  return topChampions(rows, n, { roster, exclude: bannedAndPicked });
}

window.lolScout = { HEADERS, ROLE_ROSTERS, calcularPeso, parseSnapshot, topChampions, recommendForRole };
