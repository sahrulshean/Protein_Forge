from collections import Counter
from itertools import product
import random

import pytest

from protein_forge.game import codon_entries, make_game


def test_reference_covers_every_rna_codon_exactly_once():
    entries = codon_entries()
    expected = {"".join(bases) for bases in product("ACGU", repeat=3)}

    assert len(entries) == 64
    assert {entry["codon"] for entry in entries} == expected
    assert {entry["code"] for entry in entries} == set("ACDEFGHIKLMNPQRSTVWY*")
    assert all(entry["name"] for entry in entries)


@pytest.mark.parametrize("codon, code, name", [
    ("AUG", "M", "Metionin"),
    ("UGG", "W", "Triptofan"),
    ("UUU", "F", "Fenilalanin"),
    ("UUC", "F", "Fenilalanin"),
    ("GCU", "A", "Alanin"),
    ("AGU", "S", "Serin"),
    ("AGA", "R", "Arginin"),
    ("AUA", "I", "Isoleusin"),
    ("UAA", "*", "Stop"),
    ("UAG", "*", "Stop"),
    ("UGA", "*", "Stop"),
])
def test_reference_matches_standard_genetic_code(codon, code, name):
    entries = {entry["codon"]: entry for entry in codon_entries()}
    assert entries[codon] == {"codon": codon, "code": code, "name": name}


def test_standard_code_degeneracy():
    counts = Counter(entry["code"] for entry in codon_entries())
    assert counts == {
        "A": 4, "C": 2, "D": 2, "E": 2, "F": 2, "G": 4, "H": 2,
        "I": 3, "K": 2, "L": 6, "M": 1, "N": 2, "P": 4, "Q": 2,
        "R": 6, "S": 6, "T": 4, "V": 4, "W": 1, "Y": 2, "*": 3,
    }


@pytest.mark.parametrize("seed", [0, 1, 7, 42, 100])
def test_game_builds_five_residue_peptide_then_stops(seed):
    questions = make_game(random.Random(seed))["questions"]
    reference = {entry["codon"]: entry for entry in codon_entries()}
    names = {entry["code"]: entry["name"] for entry in reference.values()}

    assert len(questions) == 6
    assert [question["id"] for question in questions] == list(range(1, 7))
    assert questions[0]["codon"] == "AUG"
    assert questions[0]["answer"] == "M"
    assert questions[-1]["codon"] in {"UAA", "UAG", "UGA"}
    assert questions[-1]["answer"] == "*"
    assert all(question["answer"] != "*" for question in questions[:-1])
    assert len({question["codon"] for question in questions}) == 6

    for question in questions:
        assert question["answer"] == reference[question["codon"]]["code"]
        options = question["options"]
        assert len(options) == 4
        assert len({option["code"] for option in options}) == 4
        assert question["answer"] in {option["code"] for option in options}
        assert all(option["name"] == names[option["code"]] for option in options)
        assert question["codon"] in question["explanation"]
    assert "tidak menyandi asam amino" in questions[-1]["explanation"]


def test_seed_makes_lessons_reproducible():
    assert make_game(random.Random(12)) == make_game(random.Random(12))
    assert make_game(random.Random(12)) != make_game(random.Random(13))


def test_game_can_be_created_without_supplied_random_generator():
    assert len(make_game()["questions"]) == 6
