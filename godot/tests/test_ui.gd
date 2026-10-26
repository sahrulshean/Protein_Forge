extends SceneTree

var failures: Array[String] = []
var checks: int = 0
var capture_dir: String = OS.get_environment("PROTEIN_FORGE_CAPTURE_DIR")


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)


func _capture(filename: String) -> void:
	if capture_dir.is_empty() or DisplayServer.get_name() == "headless":
		return
	DirAccess.make_dir_recursive_absolute(capture_dir)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var picture: Image = root.get_texture().get_image()
	_check(not picture.is_empty(), "Rendered image must not be empty.")
	_check(picture.save_png(capture_dir.path_join(filename)) == OK, "Screenshot is saved.")


func _run() -> void:
	root.size = Vector2i(1280, 800)
	var packed: PackedScene = load("res://godot/scenes/main.tscn")
	if packed == null:
		push_error("Cannot load the main scene.")
		quit(1)
		return
	var game: Variant = packed.instantiate()
	root.add_child(game)
	await process_frame
	_check(game.screen == "welcome", "Project opens on welcome screen.")
	_check(game.start_button.is_visible_in_tree(), "Start button is visible.")
	await _capture("welcome.png")
	game.start_button.pressed.emit()
	await process_frame
	_check(game.screen == "game", "Start button opens the game.")
	_check(game.answer_buttons.size() == 4, "Four answer buttons are rendered.")
	_check(game.session.score == 0, "New game starts at zero points.")
	game.next_round()
	_check(game.session.index == 0, "Next cannot skip unanswered round.")
	var question: Dictionary = game.session.current_question()
	var wrong_index: int = -1
	for i: int in range(4):
		if question["options"][i]["code"] != question["answer"]:
			wrong_index = i
			break
	game.answer_buttons[wrong_index].pressed.emit()
	_check(game.session.score == 0 and game.session.attempted, "Wrong button records attempt without points.")
	_check(game.answer_buttons[wrong_index].disabled, "Wrong choice cannot be submitted repeatedly.")
	for round_index: int in range(6):
		question = game.session.current_question()
		var answer_index: int = -1
		for i: int in range(4):
			if question["options"][i]["code"] == question["answer"]:
				answer_index = i
				break
		game.answer_buttons[answer_index].pressed.emit()
		await process_frame
		_check(game.session.score == 50 + round_index * 100, "Correct button awards score once.")
		_check(game.score_label.text.contains(str(game.session.score)), "Score display matches session.")
		_check(game.session.chain.size() == mini(round_index + 1, 5), "UI session excludes STOP from chain.")
		_check(game.next_button.is_visible_in_tree() and not game.next_button.disabled, "Resolved round offers Next.")
		game.choose_answer(question["answer"])
		_check(game.session.score == 50 + round_index * 100, "Repeated answer cannot add points.")
		if round_index == 1:
			await _capture("game.png")
		game.next_button.pressed.emit()
		await process_frame
	_check(game.screen == "result", "Six completed rounds show results.")
	_check(game.session.score == 550 and game.session.first_try == 5, "One mistake ends with score550 and accuracy5/6.")
	_check(game.result_score_label.text.contains("550"), "Results show final score.")
	_check(game.session.chain.size() == 5, "Final peptide has five residues.")
	await _capture("result.png")
	game.restart_button.pressed.emit()
	await process_frame
	_check(game.screen == "game" and game.session.index == 0, "Replay starts the first round.")
	_check(game.session.score == 0 and game.session.chain.is_empty(), "Replay resets score and chain.")
	game.open_reference()
	await process_frame
	_check(game.reference_dialog.visible, "Reference popup opens.")
	_check(game.reference_rows.get_child_count() == 64, "Reference includes64 codons.")
	game.search_input.text = "AUG"
	game.search_input.text_changed.emit("AUG")
	await process_frame
	_check(game.reference_rows.get_child_count() == 1, "Reference search finds AUG.")
	game.search_input.text = "stop"
	game.search_input.text_changed.emit("stop")
	await process_frame
	_check(game.reference_rows.get_child_count() == 3, "Reference finds all3 stop codons.")
	await _capture("reference.png")
	var escape: InputEventKey = InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	Input.parse_input_event(escape)
	await process_frame
	_check(not game.reference_dialog.visible, "Escape closes reference popup.")
	game.open_reference()
	await process_frame
	game.close_reference()
	_check(not game.reference_dialog.visible, "Reference close action works.")
	root.size = Vector2i(800, 600)
	await _capture("compact.png")
	game.open_reference()
	await process_frame
	_check(game.reference_dialog.size.y <= int(root.get_visible_rect().size.y), "Reference fits the compact viewport height.")
	await _capture("compact-reference.png")
	game.close_reference()
	question = game.session.current_question()
	var shortcut: InputEventKey = InputEventKey.new()
	shortcut.pressed = true
	for i: int in range(4):
		if question["options"][i]["code"] == question["answer"]:
			shortcut.keycode = KEY_1 + i
	Input.parse_input_event(shortcut)
	await process_frame
	_check(game.session.score == 100, "Number-key shortcut answers the current question.")
	game.queue_free()
	await process_frame
	game = packed.instantiate()
	root.add_child(game)
	await process_frame
	_check(game.best_score >= 550, "Personal record survives scene recreation.")
	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("PASS: %d Godot UI checks." % checks)
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		print("FAIL: %d of %d Godot UI checks." % [failures.size(), checks])
		quit(1)
