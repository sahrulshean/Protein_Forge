"""Validation for sequences of the 20 canonical amino acids."""

AMINO_ACIDS = frozenset("ACDEFGHIKLMNPQRSTVWY")


def normalize_sequence(sequence: str) -> str:
    """Remove whitespace and uppercase a canonical amino acid sequence.

    Empty sequences, ambiguous residues, stop markers, and non-ASCII residue
    symbols raise ValueError. FASTA headers are not accepted.
    """
    compact = "".join(sequence.split())
    if not compact:
        raise ValueError("Urutan protein tidak boleh kosong.")
    if not compact.isascii():
        raise ValueError("Gunakan kode huruf ASCII untuk asam amino.")

    normalized = compact.upper()
    invalid = set(normalized) - AMINO_ACIDS
    if invalid:
        raise ValueError(f"Simbol asam amino tidak didukung: {', '.join(sorted(invalid))}")
    return normalized
