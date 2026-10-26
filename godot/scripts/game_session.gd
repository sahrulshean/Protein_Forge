class_name ProteinGameSession
extends RefCounted
## Six translation rounds using the standard genetic code.

const AMINO_ACID_NAMES: Dictionary = {
	"A": "Alanin", "R": "Arginin", "N": "Asparagin", "D": "Aspartat",
	"C": "Sistein", "Q": "Glutamin", "E": "Glutamat", "G": "Glisin",
	"H": "Histidin", "I": "Isoleusin", "L": "Leusin", "K": "Lisin",
	"M": "Metionin", "F": "Fenilalanin", "P": "Prolin", "S": "Serin",
	"T": "Treonin", "W": "Triptofan", "Y": "Tirosin", "V": "Valin",
	"*": "Stop",
}

const CODON_GROUPS: Dictionary = {
	"F": "UUU UUC", "L": "UUA UUG CUU CUC CUA CUG", "I": "AUU AUC AUA",
	"M": "AUG", "V": "GUU GUC GUA GUG", "S": "UCU UCC UCA UCG AGU AGC",
	"P": "CCU CCC CCA CCG", "T": "ACU ACC ACA ACG", "A": "GCU GCC GCA GCG",
	"Y": "UAU UAC", "*": "UAA UAG UGA", "H": "CAU CAC", "Q": "CAA CAG",
	"N": "AAU AAC", "K": "AAA AAG", "D": "GAU GAC", "E": "GAA GAG",
	"C": "UGU UGC", "W": "UGG", "R": "CGU CGC CGA CGG AGA AGG",
	"G": "GGU GGC GGA GGG",
}

var questions: Array = []
var index: int = 0
var score: int = 0
var first_try: int = 0
var chain: Array[String] = []
var answered: bool = false
var attempted: bool = false
var finished: bool = false
var _tried_codes: Array[String] = []


static func _genetic_code() -> Dictionary:
	var mapping: Dictionary = {}
	for code: String in CODON_GROUPS:
		for codon: String in str(CODON_GROUPS[code]).split(" "):
			mapping[codon] = code
	return mapping


static func codon_entries() -> Array:
	var mapping: Dictionary = _genetic_code()
	var codons: Array = mapping.keys()
	codons.sort()
	var entries: Array = []
	for codon: String in codons:
		var code: String = mapping[codon]
		entries.append({"codon": codon, "code": code, "name": AMINO_ACID_NAMES[code]})
	return entries


static func _shuffle(values: Array, rng: RandomNumberGenerator) -> void:
	for i: int in range(values.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var temporary: Variant = values[i]
		values[i] = values[j]
		values[j] = temporary


static func make_questions(seed_value: int = -1) -> Array:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	if seed_value < 0:
		rng.randomize()
	else:
		rng.seed = seed_value
	var mapping: Dictionary = _genetic_code()
	var sense_codons: Array = []
	for entry: Dictionary in codon_entries():
		if entry["code"] != "*" and entry["codon"] != "AUG":
			sense_codons.append(entry["codon"])
	_shuffle(sense_codons, rng)
	var selected_codons: Array[String] = ["AUG"]
	for position: int in range(4):
		selected_codons.append(sense_codons[position])
	var stops: Array[String] = ["UAA", "UAG", "UGA"]
	selected_codons.append(stops[rng.randi_range(0, 2)])

	var result: Array = []
	for position: int in range(selected_codons.size()):
		var codon: String = selected_codons[position]
		var answer: String = mapping[codon]
		var candidates: Array = AMINO_ACID_NAMES.keys()
		candidates.erase(answer)
		_shuffle(candidates, rng)
		var choices: Array = [answer, candidates[0], candidates[1], candidates[2]]
		_shuffle(choices, rng)
		var options: Array = []
		for code: String in choices:
			options.append({"code": code, "name": AMINO_ACID_NAMES[code]})
		var explanation: String
		if codon == "AUG":
			explanation = "AUG menyandi metionin (M) dalam kode genetik standar. Kodon ini biasanya menjadi titik awal translasi; di sini rantai peptida dimulai dengan metionin."
		elif answer == "*":
			explanation = "%s adalah kodon stop. Kodon stop tidak menyandi asam amino: translasi berakhir tanpa menambah residu ke rantai peptida." % codon
		else:
			explanation = "Dalam kode genetik standar, %s menyandi %s (%s). Ribosom menambahkan asam amino ini ke rantai peptida." % [codon, str(AMINO_ACID_NAMES[answer]).to_lower(), answer]
		result.append({
			"id": position + 1, "codon": codon, "answer": answer,
			"options": options, "explanation": explanation,
		})
	return result


func new_game(seed_value: int = -1) -> void:
	questions = make_questions(seed_value)
	index = 0
	score = 0
	first_try = 0
	chain.clear()
	answered = false
	attempted = false
	finished = false
	_tried_codes.clear()


func current_question() -> Dictionary:
	if questions.is_empty() or finished:
		return {}
	return questions[index]


func submit_answer(code: String) -> Dictionary:
	var rejected: Dictionary = {"accepted": false, "correct": false, "points": 0}
	if questions.is_empty() or finished or answered or code in _tried_codes:
		return rejected
	var question: Dictionary = current_question()
	var available: bool = false
	for option: Dictionary in question["options"]:
		if option["code"] == code:
			available = true
			break
	if not available:
		return rejected
	_tried_codes.append(code)
	if code != question["answer"]:
		attempted = true
		return {"accepted": true, "correct": false, "points": 0}

	answered = true
	var points: int = 50 if attempted else 100
	score += points
	if not attempted:
		first_try += 1
	if code != "*":
		chain.append(code)
	return {"accepted": true, "correct": true, "points": points, "explanation": question["explanation"]}


func advance() -> bool:
	if questions.is_empty() or finished or not answered:
		return false
	if index == questions.size() - 1:
		finished = true
		return true
	index += 1
	answered = false
	attempted = false
	_tried_codes.clear()
	return true
