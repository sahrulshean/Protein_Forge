"""Short peptide-building lessons using the standard genetic code."""

import random

AMINO_ACID_NAMES = {
    "A": "Alanin",
    "R": "Arginin",
    "N": "Asparagin",
    "D": "Aspartat",
    "C": "Sistein",
    "Q": "Glutamin",
    "E": "Glutamat",
    "G": "Glisin",
    "H": "Histidin",
    "I": "Isoleusin",
    "L": "Leusin",
    "K": "Lisin",
    "M": "Metionin",
    "F": "Fenilalanin",
    "P": "Prolin",
    "S": "Serin",
    "T": "Treonin",
    "W": "Triptofan",
    "Y": "Tirosin",
    "V": "Valin",
    "*": "Stop",
}

# RNA codons, grouped by their translation in the standard genetic code.
_CODON_GROUPS = {
    "F": "UUU UUC",
    "L": "UUA UUG CUU CUC CUA CUG",
    "I": "AUU AUC AUA",
    "M": "AUG",
    "V": "GUU GUC GUA GUG",
    "S": "UCU UCC UCA UCG AGU AGC",
    "P": "CCU CCC CCA CCG",
    "T": "ACU ACC ACA ACG",
    "A": "GCU GCC GCA GCG",
    "Y": "UAU UAC",
    "*": "UAA UAG UGA",
    "H": "CAU CAC",
    "Q": "CAA CAG",
    "N": "AAU AAC",
    "K": "AAA AAG",
    "D": "GAU GAC",
    "E": "GAA GAG",
    "C": "UGU UGC",
    "W": "UGG",
    "R": "CGU CGC CGA CGG AGA AGG",
    "G": "GGU GGC GGA GGG",
}
GENETIC_CODE = {
    codon: code
    for code, codons in _CODON_GROUPS.items()
    for codon in codons.split()
}


def codon_entries() -> list[dict[str, str]]:
    """Return all 64 RNA codons with their residue code and Indonesian name."""
    return [
        {"codon": codon, "code": code, "name": AMINO_ACID_NAMES[code]}
        for codon, code in sorted(GENETIC_CODE.items())
    ]


def make_game(rng: random.Random | None = None) -> dict:
    """Create six rounds: a start codon, four sense codons, then a stop.

    The lesson builds a five-residue peptide, not a functional protein.
    Inject a seeded Random instance for reproducible lessons and tests.
    """
    if rng is None:
        rng = random.Random()
    sense_codons = [
        codon for codon, code in GENETIC_CODE.items()
        if code != "*" and codon != "AUG"
    ]
    codons = ["AUG", *rng.sample(sense_codons, 4), rng.choice(["UAA", "UAG", "UGA"])]
    questions = []
    for index, codon in enumerate(codons, start=1):
        answer = GENETIC_CODE[codon]
        choices = [answer, *rng.sample([
            code for code in AMINO_ACID_NAMES if code != answer
        ], 3)]
        rng.shuffle(choices)
        name = AMINO_ACID_NAMES[answer]
        if codon == "AUG":
            explanation = (
                "AUG menyandi metionin (M) dalam kode genetik standar. "
                "Kodon ini biasanya menjadi titik awal translasi; "
                "di sini, rantai peptida dimulai dengan metionin."
            )
        elif answer == "*":
            explanation = (
                f"{codon} adalah kodon stop dalam kode genetik standar. "
                "Kodon stop tidak menyandi asam amino: translasi berakhir "
                "tanpa menambahkan residu ke rantai peptida."
            )
        else:
            explanation = (
                f"Dalam kode genetik standar, {codon} menyandi {name.lower()} "
                f"({answer}). Ribosom menambahkan asam amino ini ke rantai peptida."
            )
        questions.append({
            "id": index,
            "codon": codon,
            "answer": answer,
            "options": [
                {"code": code, "name": AMINO_ACID_NAMES[code]} for code in choices
            ],
            "explanation": explanation,
        })
    return {"questions": questions}
