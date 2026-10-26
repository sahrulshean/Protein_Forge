extends SceneTree

const GameSession = preload("res://godot/scripts/game_session.gd")
var failures: Array[String] = []
var checks: int = 0


func _initialize() -> void:
	_test_reference()
	_test_questions()
	_test_perfect_game()
	_test_mistakes_and_restart()
	if failures.is_empty():
		print("PASS: %d Godot session checks." % checks)
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		print("FAIL: %d of %d Godot session checks." % [failures.size(), checks])
		quit(1)


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)


func _test_reference() -> void:
	var entries: Array = GameSession.codon_entries()
	var mapping: Dictionary = {}
	var counts: Dictionary = {}
	for entry: Dictionary in entries:
		mapping[entry["codon"]] = entry["code"]
		var code: String = entry["code"]
		counts[code] = int(counts.get(code, 0)) + 1
		_check(not str(entry["name"]).is_empty(), "Every residue needs a name.")
	_check(entries.size() == 64 and mapping.size() == 64, "There must be 64 unique codons.")
	for a: String in ["A", "C", "G", "U"]:
		for b: String in ["A", "C", "G", "U"]:
			for c: String in ["A", "C", "G", "U"]:
				_check(mapping.has(a + b + c), "Missing RNA codon: " + a + b + c)
	var known: Dictionary = {"AUG": "M", "UGG": "W", "UUU": "F", "UUC": "F", "GCU": "A", "AGU": "S", "AGA": "R", "AUA": "I", "UAA": "*", "UAG": "*", "UGA": "*"}
	for codon: String in known:
		_check(mapping.get(codon) == known[codon], "Incorrect standard mapping: " + codon)
	var expected_counts: Dictionary = {"A": 4, "C": 2, "D": 2, "E": 2, "F": 2, "G": 4, "H": 2, "I": 3, "K": 2, "L": 6, "M": 1, "N": 2, "P": 4, "Q": 2, "R": 6, "S": 6, "T": 4, "V": 4, "W": 1, "Y": 2, "*": 3}
	_check(counts == expected_counts, "Standard code degeneracy must match.")


func _test_questions() -> void:
	var mapping: Dictionary = {}
	for entry: Dictionary in GameSession.codon_entries():
		mapping[entry["codon"]] = entry["code"]
	for seed_value: int in [0, 1, 7, 42, 100]:
		var questions: Array = GameSession.make_questions(seed_value)
		_check(questions.size() == 6, "A game has six rounds.")
		_check(questions[0]["codon"] == "AUG" and questions[0]["answer"] == "M", "Start with AUG/metionin.")
		_check(questions[-1]["answer"] == "*", "Last round must be stop.")
		var seen: Dictionary = {}
		for i: int in range(questions.size()):
			var question: Dictionary = questions[i]
			seen[question["codon"]] = true
			_check(question["id"] == i + 1, "Question IDs are sequential.")
			_check(mapping[question["codon"]] == question["answer"], "Question answer matches standard code.")
			_check(str(question["explanation"]).contains(question["codon"]), "Explanation identifies the codon.")
			if i < 5:
				_check(question["answer"] != "*", "No stop before final round.")
			var options: Array = question["options"]
			var choices: Dictionary = {}
			for option: Dictionary in options:
				choices[option["code"]] = true
				_check(GameSession.AMINO_ACID_NAMES.get(option["code"]) == option["name"], "Option name matches residue code.")
			_check(options.size() == 4 and choices.size() == 4, "Four distinct answer choices.")
			_check(choices.has(question["answer"]), "Options include correct answer.")
		_check(seen.size() == 6, "All six codons are distinct.")
	_check(GameSession.make_questions(12) == GameSession.make_questions(12), "Seeded generation is reproducible.")
	_check(GameSession.make_questions(12) != GameSession.make_questions(13), "Different seeds produce different games.")
	_check(GameSession.make_questions().size() == 6, "Unseeded generation works.")


func _test_perfect_game() -> void:
	var session: RefCounted = GameSession.new()
	_check(session.current_question().is_empty(), "Session is empty before start.")
	_check(not session.advance(), "Cannot advance before start.")
	_check(not session.submit_answer("M")["accepted"], "Cannot answer before start.")
	session.new_game(7)
	for i: int in range(6):
		_check(not session.advance(), "Cannot advance before correct answer.")
		var answer: String = session.current_question()["answer"]
		var result: Dictionary = session.submit_answer(answer)
		_check(result["accepted"] and result["correct"] and result["points"] == 100, "First correct answer awards 100.")
		_check(session.chain.size() == mini(i + 1, 5), "STOP adds no residue.")
		_check(not session.submit_answer(answer)["accepted"], "Repeated answers cannot score twice.")
		_check(session.score == (i + 1) * 100, "Perfect score increases once per round.")
		_check(session.advance(), "Resolved round advances.")
	_check(session.finished and session.score == 600 and session.first_try == 6, "Perfect run ends at 600 / 6 first-try answers.")
	_check(session.chain.size() == 5 and not "*" in session.chain, "Completed chain is five residues without stop.")
	_check(session.current_question().is_empty(), "Finished game has no current question.")
	_check(not session.advance(), "Finished game cannot advance again.")
	_check(not session.submit_answer("M")["accepted"], "Finished game cannot accept answers.")


func _test_mistakes_and_restart() -> void:
	var session: RefCounted = GameSession.new()
	session.new_game(42)
	_check(not session.submit_answer("not-a-residue")["accepted"], "Unsupported input rejected.")
	_check(not session.attempted and session.score == 0, "Invalid input does not penalize player.")
	var current: Dictionary = session.current_question()
	var wrong: String = ""
	for option: Dictionary in current["options"]:
		if option["code"] != current["answer"]:
			wrong = option["code"]
			break
	var result: Dictionary = session.submit_answer(wrong)
	_check(result["accepted"] and not result["correct"] and result["points"] == 0, "Wrong valid choice gives no points.")
	_check(session.attempted and not session.answered and session.chain.is_empty(), "Wrong answer marks attempt without adding residue.")
	_check(not session.submit_answer(wrong)["accepted"], "Repeated wrong choice is ignored.")
	_check(not session.advance(), "Wrong answer cannot advance.")
	for i: int in range(6):
		result = session.submit_answer(session.current_question()["answer"])
		_check(result["points"] == (50 if i == 0 else 100), "Penalty applies only to the mistaken round.")
		_check(session.advance(), "Corrected round advances.")
	_check(session.score == 550 and session.first_try == 5, "One mistake ends at 550 and five first-try answers.")
	var previous: Array = session.questions.duplicate(true)
	session.new_game(12)
	_check(session.score == 0 and session.first_try == 0 and session.index == 0, "Restart resets counters.")
	_check(session.chain.is_empty() and not session.answered and not session.attempted and not session.finished, "Restart resets all progress flags.")
	_check(session.questions != previous and session.questions.size() == 6, "Restart generates fresh questions.")
