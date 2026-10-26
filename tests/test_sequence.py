import pytest

from protein_forge import normalize_sequence


def test_accepts_all_canonical_amino_acids():
    sequence = "ACDEFGHIKLMNPQRSTVWY"
    assert normalize_sequence(sequence) == sequence


def test_normalizes_case_and_whitespace():
    assert normalize_sequence("  acd\nef\tgh\r\n ") == "ACDEFGH"


@pytest.mark.parametrize("sequence", ["", " \n\t"])
def test_rejects_empty_sequences(sequence):
    with pytest.raises(ValueError, match="tidak boleh kosong"):
        normalize_sequence(sequence)


@pytest.mark.parametrize("sequence", ["ACB", "ACX", "ACU", "ACO", "ACZ", "ACJ", "AC1", "AC*", "AC-", ">protein\nACD"])
def test_rejects_unsupported_symbols(sequence):
    with pytest.raises(ValueError, match="tidak didukung"):
        normalize_sequence(sequence)


@pytest.mark.parametrize("sequence", ["AßC", "ＡＣＤ", "ACé"])
def test_rejects_non_ascii_residues(sequence):
    with pytest.raises(ValueError, match="ASCII"):
        normalize_sequence(sequence)
