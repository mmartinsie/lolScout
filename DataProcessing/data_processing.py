"""Turns a patch snapshot CSV into a champion pick recommendation.

Run directly for the interactive CLI (`python data_processing.py`), or import
`calcularPeso`, `top_champions` and `recommend_for_role` to use the scoring logic on its
own (see ../tests/test_data_processing.py).
"""
import pandas as pd

HEADERS = ["Name", "Popularity", "WR", "Banrate", "Main", "Pentakills", "Gold", "Minions",
           "Wards", "Damage"]

TOP = ["aatrox", "camille", "cho'gath", "darius", "dr. mundo", "fiora", "gangplank", "garen",
       "gnar", "gwen", "illaoi", "irelia", "jax", "jayce", "kayle", "kennen", "kled", "malphite",
       "maokai", "mordekaiser", "nasus", "ornn", "pantheon", "poppy", "quinn", "renekton", "riven",
       "rumble", "sett", "shen", "singed", "sion", "tahm kench", "teemo", "trundle", "tryndamere",
       "urgot", "yorick"]
JUNGLE = ["amumu", "diana", "ekko", "elise", "evelynn", "fiddlesticks", "gragas", "graves",
          "hecarim", "ivern", "jarvan iv", "karthus", "kayn", "kha'zix", "kindred", "lee sin",
          "lillia", "master yi", "nidalee", "nocturne", "nunu & willump", "olaf", "rammus",
          "rek'sai", "rengar", "sejuani", "shaco", "shyvana", "skarner", "taliyah", "talon",
          "udyr", "vi", "viego", "volibear", "warwick", "wukong", "xin zhao", "zac"]
MID = ["ahri", "akali", "akshan", "anivia", "annie", "aurelion sol", "azir", "cassiopeia",
       "corki", "fizz", "galio", "heimerdinger", "kassadin", "katarina", "leblanc", "lissandra",
       "malzahar", "neeko", "orianna", "qiyana", "ryze", "sylas", "syndra", "twisted fate",
       "veigar", "vex", "viktor", "vladimir", "xerath", "yasuo", "yone", "zed", "ziggs", "zoe"]
ADC = ["aphelios", "ashe", "caitlyn", "draven", "ezreal", "jhin", "jinx", "kai'sa", "kalista",
       "kog'maw", "lucian", "miss fortune", "samira", "sivir", "tristana", "twitch", "varus",
       "vayne", "xayah", "zeri"]
SUPPORT = ["alistar", "bard", "blitzcrank", "brand", "braum", "janna", "karma", "leona", "lulu",
           "lux", "morgana", "nami", "nautilus", "pyke", "rakan", "rell", "renata glasc", "senna",
           "seraphine", "sona", "soraka", "swain", "taric", "thresh", "vel'koz", "yuumi",
           "zilean", "zyra"]

# Role rosters are a snapshot of the meta at the time this was written and will drift as
# champions' common roles shift — update the lists above as needed.
ROLE_ROSTERS = {"top": TOP, "jung": JUNGLE, "mid": MID, "adc": ADC, "supp": SUPPORT}


def calcularPeso(row):
    """Weighted score used to rank champions (see DataProcessing/README.md for the
    rationale behind each weight). `row` is a pandas Series with the HEADERS columns."""
    return (row.WR + 0.6 * row.Popularity + 0.4 * row.Banrate + row.Main
            + 100 * row.Pentakills + 0.5 * row.Minions + 2 * row.Wards)


def load_snapshot(csv_path="champInfoVersionCSV.csv"):
    """Load a ';'-separated, headerless patch snapshot CSV into a DataFrame."""
    return pd.read_csv(csv_path, sep=';', header=None, names=HEADERS)


def top_champions(df, n=5, names=None, exclude=()):
    """Top-`n` champion names by weighted score.

    `names` restricts the pool to a role roster (e.g. MID); `exclude` removes already
    picked/banned champions from consideration.
    """
    pool = df
    if names is not None:
        pool = pool[pool.Name.isin(names)]
    if exclude:
        pool = pool[~pool.Name.isin(exclude)]
    scores = pool.apply(calcularPeso, axis=1)
    return pool.assign(Peso=scores).nlargest(n, 'Peso')['Name'].tolist()


def recommend_for_role(df, role, banned_and_picked, n=3):
    """Top-`n` available champions for `role` (a key of ROLE_ROSTERS), excluding
    `banned_and_picked` champion names."""
    roster = ROLE_ROSTERS.get(role)
    if roster is None:
        raise ValueError(f"Unknown role {role!r}; expected one of {sorted(ROLE_ROSTERS)}")
    return top_champions(df, n=n, names=roster, exclude=banned_and_picked)


def _prompt_names(label, count):
    print(f"{label}: ")
    return [input().strip() for _ in range(count)]


def _prompt_role():
    print("Posición elegida (mid,top,jung,adc,supp): ")
    role = input().strip()
    while role not in ROLE_ROSTERS:
        print(f"Rol no reconocido: {role!r}. Usa uno de {sorted(ROLE_ROSTERS)}.")
        role = input().strip()
    return role


def main():
    df = load_snapshot()

    best_five = top_champions(df, n=5)
    print("Los cinco mejores campeones de la version son")
    for i, name in enumerate(best_five, start=1):
        print(f" {i}) {name}")

    role = _prompt_role()
    picked = _prompt_names("Nombre de los 9 campeones elegidos por ambos equipos", 9)
    banned = _prompt_names("Nombre de los 10 campeones baneados por ambos equipos", 10)

    best_three = recommend_for_role(df, role, picked + banned, n=3)
    print(f"Las tres mejores elecciones para la posición {role} son")
    for i, name in enumerate(best_three, start=1):
        print(f" {i}) {name}")


if __name__ == "__main__":
    main()
