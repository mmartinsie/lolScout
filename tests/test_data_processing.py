"""Tests for the scoring/recommendation logic in DataProcessing/data_processing.py.

These exercise the formula and selection logic in isolation from the interactive CLI
(`main()`), which is intentionally left untested here since it just wraps `input()`.
"""
import pandas as pd
import pytest

from data_processing import HEADERS, calcularPeso, recommend_for_role, top_champions


def make_df(rows):
    return pd.DataFrame(rows, columns=["Name", "Popularity", "WR", "Banrate", "Main",
                                        "Pentakills", "Minions", "Wards"])


def test_calcularPeso_matches_the_documented_formula():
    row = pd.Series({"Popularity": 10.0, "WR": 50.0, "Banrate": 5.0, "Main": 1.0,
                      "Pentakills": 0.01, "Minions": 6.0, "Wards": 0.3})
    expected = 50.0 + 0.6 * 10.0 + 0.4 * 5.0 + 1.0 + 100 * 0.01 + 0.5 * 6.0 + 2 * 0.3
    assert calcularPeso(row) == pytest.approx(expected)


def test_calcularPeso_ignores_gold_and_damage():
    # Gold/Damage are captured (see scrap_champ.py) but aren't part of the scoring
    # formula; a row missing them entirely should score the same as one with them.
    with_extra = pd.Series({"Popularity": 10.0, "WR": 50.0, "Banrate": 5.0, "Main": 1.0,
                             "Pentakills": 0.01, "Minions": 6.0, "Wards": 0.3,
                             "Gold": 500.0, "Damage": 12000.0})
    without_extra = with_extra.drop(["Gold", "Damage"])
    assert calcularPeso(with_extra) == calcularPeso(without_extra)


def test_top_champions_orders_by_score_descending():
    df = make_df([
        ["low", 1.0, 40.0, 1.0, 0.1, 0.0, 5.0, 0.1],
        ["high", 10.0, 60.0, 10.0, 2.0, 0.01, 8.0, 1.0],
        ["mid", 5.0, 50.0, 5.0, 1.0, 0.005, 6.0, 0.5],
    ])
    assert top_champions(df, n=2) == ["high", "mid"]


def test_top_champions_can_restrict_to_a_roster_and_exclude_names():
    df = make_df([
        ["ahri", 10.0, 60.0, 10.0, 2.0, 0.01, 8.0, 1.0],
        ["zed", 9.0, 55.0, 9.0, 1.5, 0.008, 7.0, 0.8],
        ["garen", 20.0, 70.0, 20.0, 3.0, 0.02, 9.0, 2.0],
    ])
    result = top_champions(df, n=5, names=["ahri", "zed"], exclude=["zed"])
    assert result == ["ahri"]


def test_recommend_for_role_uses_the_matching_roster():
    df = make_df([
        ["ahri", 10.0, 60.0, 10.0, 2.0, 0.01, 8.0, 1.0],   # mid roster
        ["garen", 20.0, 70.0, 20.0, 3.0, 0.02, 9.0, 2.0],  # top roster
    ])
    assert recommend_for_role(df, "mid", banned_and_picked=[]) == ["ahri"]
    assert recommend_for_role(df, "top", banned_and_picked=[]) == ["garen"]


def test_recommend_for_role_rejects_an_unknown_role():
    df = make_df([["ahri", 10.0, 60.0, 10.0, 2.0, 0.01, 8.0, 1.0]])
    with pytest.raises(ValueError):
        recommend_for_role(df, "carry", banned_and_picked=[])


def test_headers_match_the_row_scrap_champ_now_saves():
    # scrap_champ.py's complete_info list is:
    # [champ, popularity, wr, banrate, main, pentakills, gold, minions, wards, damage]
    assert HEADERS == ["Name", "Popularity", "WR", "Banrate", "Main", "Pentakills", "Gold",
                        "Minions", "Wards", "Damage"]
