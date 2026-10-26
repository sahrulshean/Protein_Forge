"""Command-line example for validating a protein sequence."""

import argparse
import json

from protein_forge.sequence import normalize_sequence


def main() -> int:
    parser = argparse.ArgumentParser(description="Validasi urutan protein sederhana.")
    parser.add_argument("sequence", help="Urutan kode satu huruf asam amino, misalnya ACDEF.")
    args = parser.parse_args()
    try:
        sequence = normalize_sequence(args.sequence)
    except ValueError as error:
        parser.error(str(error))
    print(json.dumps({"sequence": sequence, "length": len(sequence)}))
    return 0
