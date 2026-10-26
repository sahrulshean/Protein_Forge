extends Control

const Session = preload("res://godot/scripts/game_session.gd")
const BACKGROUND = Color("101820")
const PANEL = Color("17222b")
const SOFT_PANEL = Color("1d2a34")
const LINE = Color("34434d")
const TEXT = Color("f1f4ef")
const MUTED = Color("a5b2bb")
const LIME = Color("c9f27e")
const VIOLET = Color("bcacf7")
const DANGER = Color("ffb0a6")
const SAVE_PATH = "user://progress.cfg"

var session = Session.new()
var screen: String = "welcome"
var reference_rows: VBoxContainer
var reference_dialog: PopupPanel
var answer_buttons: Array[Button] = []
var start_button: Button
var next_button: Button
var restart_button: Button
var score_label: Label
var result_score_label: Label
var search_input: LineEdit
var best_score: int:
	get:
		return _best_score

var _welcome: VBoxContainer
var _game: VBoxContainer
var _result: VBoxContainer
var _page_scroll: ScrollContainer
var _round_label: Label
var _codon_track: HBoxContainer
var _current_codon: HBoxContainer
var _answer_grid: GridContainer
var _feedback: Label
var _best_label: Label
var _chain_row: HBoxContainer
var _chain_count: Label
var _accuracy_label: Label
var _final_chain: HBoxContainer
var _record_label: Label
var _reference_count: Label
var _reference_return_focus: Control
var _help_dialog: AcceptDialog
var _best_score: int = 0


func _ready() -> void:
	get_window().min_size = Vector2i(800, 600)
	get_viewport().gui_embed_subwindows = true
	_best_score = _read_best_score()
	_build_theme()
	var background := ColorRect.new()
	background.color = BACKGROUND
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	_page_scroll = ScrollContainer.new()
	_page_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_page_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_page_scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	_page_scroll.add_child(margin)
	var page := _vbox(22)
	margin.add_child(page)
	_build_header(page)
	page.add_child(HSeparator.new())
	_welcome = _vbox(28)
	_game = _vbox(18)
	_result = _vbox(18)
	page.add_child(_welcome)
	page.add_child(_game)
	page.add_child(_result)
	_build_welcome()
	_build_game()
	_build_result()
	page.add_child(HSeparator.new())
	page.add_child(_label("PROTEIN FORGE   /   KODE GENETIK STANDAR   /   DIRAKIT DENGAN RASA INGIN TAHU", 11, MUTED))
	_build_reference()
	_build_help()
	_show_screen("welcome")
	start_button.grab_focus()


func _build_theme() -> void:
	theme = Theme.new()
	theme.default_font_size = 16
	theme.set_color("font_color", "Label", TEXT)
	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_hover_color", "Button", TEXT)
	theme.set_color("font_pressed_color", "Button", TEXT)
	theme.set_color("font_disabled_color", "Button", MUTED)
	theme.set_stylebox("normal", "Button", _style(SOFT_PANEL, LINE, 8, 14))
	theme.set_stylebox("hover", "Button", _style(Color("26382f"), LIME, 8, 14))
	theme.set_stylebox("pressed", "Button", _style(Color("314432"), LIME, 8, 14))
	theme.set_stylebox("disabled", "Button", _style(PANEL, LINE, 8, 14))
	theme.set_stylebox("focus", "Button", _style(Color.TRANSPARENT, VIOLET, 8, 0, 2))
	theme.set_stylebox("panel", "PopupPanel", _style(PANEL, LINE, 12, 0))
	theme.set_stylebox("normal", "LineEdit", _style(SOFT_PANEL, LINE, 6, 12))
	theme.set_stylebox("focus", "LineEdit", _style(Color.TRANSPARENT, VIOLET, 6, 0, 2))
	theme.set_color("font_color", "LineEdit", TEXT)
	theme.set_color("font_placeholder_color", "LineEdit", MUTED)
	theme.set_color("caret_color", "LineEdit", LIME)
	theme.set_color("selection_color", "LineEdit", Color("475c36"))


func _build_header(page: VBoxContainer) -> void:
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	page.add_child(header)
	header.add_child(_chip("PF", Vector2(48, 48), LIME))
	var branding := _vbox(2)
	branding.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(branding)
	branding.add_child(_label("PROTEIN FORGE", 23, TEXT))
	branding.add_child(_label("RUANG BERMAIN BIOLOGI", 11, MUTED))
	var help := _button("Cara bermain")
	help.pressed.connect(func() -> void: _help_dialog.popup_centered_clamped(Vector2i(580, 430), 0.9))
	header.add_child(help)
	var reference := _button("Tabel kodon")
	reference.pressed.connect(open_reference)
	header.add_child(reference)


func _build_welcome() -> void:
	_welcome.add_child(_label("LABORATORIUM INTERAKTIF  /  01", 12, LIME))
	var hero := HBoxContainer.new()
	hero.add_theme_constant_override("separation", 30)
	_welcome.add_child(hero)
	var copy := _vbox(18)
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.size_flags_stretch_ratio = 1.15
	hero.add_child(copy)
	copy.add_child(_label("Kode kecil.", 47))
	copy.add_child(_label("Penemuan besar.", 47, LIME))
	copy.add_child(_label("Di balik setiap protein, ada pesan tiga huruf. Baca kodon mRNA, pilih asam amino, dan rakit rantai peptidamu sendiri.", 18, MUTED))
	start_button = _button("Mulai merakit", true)
	start_button.pressed.connect(func() -> void: start_game())
	start_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	copy.add_child(start_button)
	copy.add_child(_label("6 kodon   ·   Tanpa batas waktu   ·   Bermain offline", 13, MUTED))
	var illustration := _panel()
	illustration.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	illustration.size_flags_stretch_ratio = 0.85
	hero.add_child(illustration)
	var demo := _vbox(20)
	illustration.add_child(demo)
	demo.add_child(_label("SIMULASI TRANSLASI", 12, MUTED))
	demo.add_child(_label("mRNA    5′ → 3′", 15, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	var letters := HBoxContainer.new()
	letters.alignment = BoxContainer.ALIGNMENT_CENTER
	letters.add_theme_constant_override("separation", 10)
	demo.add_child(letters)
	for base in ["A", "U", "G"]:
		letters.add_child(_chip(base, Vector2(62, 76), LIME, 36))
	demo.add_child(_label("↓", 28, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	demo.add_child(_label("M  ·  Metionin", 29, VIOLET, HORIZONTAL_ALIGNMENT_CENTER))
	demo.add_child(_label("Awal sebuah rantai.\n3 basa, 1 pesan.", 16, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	var steps := HBoxContainer.new()
	steps.add_theme_constant_override("separation", 22)
	_welcome.add_child(steps)
	var titles: Array[String] = ["01  Baca pesannya", "02  Temukan pasangannya", "03  Bangun rantainya"]
	var descriptions: Array[String] = ["Tiga basa mRNA membentuk satu kodon.", "Pilih asam amino yang disandi kodon itu.", "Sambungkan sampai mencapai sinyal stop."]
	for index in range(3):
		var step := _vbox(8)
		step.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		steps.add_child(step)
		step.add_child(_label(titles[index], 17, VIOLET))
		step.add_child(_label(descriptions[index], 15, MUTED))


func _build_game() -> void:
	_game.add_child(_label("EKSPERIMEN  /  TRANSLASI mRNA", 12, LIME))
	_game.add_child(_label("Satu kodon, satu langkah.", 34))
	var layout := HBoxContainer.new()
	layout.add_theme_constant_override("separation", 22)
	_game.add_child(layout)
	var question_panel := _panel()
	question_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	question_panel.size_flags_stretch_ratio = 3.0
	layout.add_child(question_panel)
	var question_box := _vbox(14)
	question_panel.add_child(question_box)
	_round_label = _label("", 13, MUTED)
	question_box.add_child(_round_label)
	_codon_track = HBoxContainer.new()
	_codon_track.add_theme_constant_override("separation", 6)
	question_box.add_child(_codon_track)
	question_box.add_child(HSeparator.new())
	question_box.add_child(_label("KODON INI MENYANDI APA?", 12, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	_current_codon = HBoxContainer.new()
	_current_codon.alignment = BoxContainer.ALIGNMENT_CENTER
	_current_codon.add_theme_constant_override("separation", 12)
	question_box.add_child(_current_codon)
	question_box.add_child(_label("Pilih asam amino atau sinyal yang tepat.", 15, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	_answer_grid = GridContainer.new()
	_answer_grid.columns = 2
	_answer_grid.add_theme_constant_override("h_separation", 12)
	_answer_grid.add_theme_constant_override("v_separation", 10)
	question_box.add_child(_answer_grid)
	_feedback = _label("", 15, MUTED)
	_feedback.custom_minimum_size.y = 66
	question_box.add_child(_feedback)
	next_button = _button("Kodon berikutnya", true)
	next_button.pressed.connect(next_round)
	question_box.add_child(next_button)
	question_box.add_child(_label("Pilih dengan klik atau tombol angka 1–4.", 12, MUTED))
	var sidebar := _vbox(16)
	sidebar.custom_minimum_size.x = 210
	sidebar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(sidebar)
	var score_panel := _panel(Color("22342b"))
	sidebar.add_child(score_panel)
	var score_box := _vbox(10)
	score_panel.add_child(score_box)
	score_box.add_child(_label("SKOR EKSPERIMEN", 12, LIME))
	score_label = _label("000", 48, LIME)
	score_box.add_child(score_label)
	score_box.add_child(_label("/ 600 poin", 14, MUTED))
	_best_label = _label("", 14, MUTED)
	score_box.add_child(_best_label)
	var chain_panel := _panel()
	sidebar.add_child(chain_panel)
	var chain_box := _vbox(14)
	chain_panel.add_child(chain_box)
	chain_box.add_child(_label("RANTAI PEPTIDAMU", 12, MUTED))
	_chain_count = _label("0 / 5 asam amino", 14, MUTED)
	chain_box.add_child(_chain_count)
	_chain_row = HBoxContainer.new()
	_chain_row.add_theme_constant_override("separation", 4)
	chain_box.add_child(_chain_row)
	chain_box.add_child(_label("Lima residu, satu rantai pendek. Stop tidak menambah asam amino.", 14, MUTED))
	sidebar.add_child(_label("CATATAN LABORATORIUM", 12, VIOLET))
	sidebar.add_child(_label("mRNA memakai U (urasil), bukan T. Satu asam amino dapat disandi beberapa kodon.", 15, MUTED))
	var reference := _button("Buka tabel kodon")
	reference.pressed.connect(open_reference)
	sidebar.add_child(reference)


func _build_result() -> void:
	_result.add_child(_label("EKSPERIMEN SELESAI", 12, LIME, HORIZONTAL_ALIGNMENT_CENTER))
	_result.add_child(_label("Pesannya berhasil dirakit.", 38, TEXT, HORIZONTAL_ALIGNMENT_CENTER))
	_result.add_child(_label("Kamu baru saja mengikuti langkah dasar translasi.", 18, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	result_score_label = _label("", 52, LIME, HORIZONTAL_ALIGNMENT_CENTER)
	_result.add_child(result_score_label)
	_accuracy_label = _label("", 18, VIOLET, HORIZONTAL_ALIGNMENT_CENTER)
	_result.add_child(_accuracy_label)
	_record_label = _label("", 15, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	_result.add_child(_record_label)
	var chain_panel := _panel()
	_result.add_child(chain_panel)
	var chain_box := _vbox(16)
	chain_panel.add_child(chain_box)
	chain_box.add_child(_label("RANTAI HASIL EKSPERIMEN", 12, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	_final_chain = HBoxContainer.new()
	_final_chain.alignment = BoxContainer.ALIGNMENT_CENTER
	_final_chain.add_theme_constant_override("separation", 12)
	chain_box.add_child(_final_chain)
	chain_box.add_child(_label("Kodon stop mengakhiri translasi tanpa menambahkan asam amino.", 15, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	_result.add_child(_label("Ini simulasi peptida lima residu. Protein nyata memiliki struktur dan fungsi yang lebih kompleks.", 15, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	restart_button = _button("Eksperimen lagi", true)
	restart_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	restart_button.pressed.connect(func() -> void: start_game())
	_result.add_child(restart_button)


func _build_reference() -> void:
	reference_dialog = PopupPanel.new()
	reference_dialog.theme = theme
	add_child(reference_dialog)
	reference_dialog.window_input.connect(_on_reference_input)
	reference_dialog.popup_hide.connect(_restore_reference_focus)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 22)
	reference_dialog.add_child(margin)
	var content := _vbox(12)
	margin.add_child(content)
	content.add_child(_label("Satu tabel, 64 pesan.", 28))
	content.add_child(_label("Kode genetik standar untuk mRNA. Baca dari arah 5′ ke 3′.", 14, MUTED))
	search_input = LineEdit.new()
	search_input.placeholder_text = "Cari kodon atau asam amino: AUG, metionin, stop…"
	search_input.custom_minimum_size.y = 44
	search_input.text_changed.connect(filter_reference)
	content.add_child(search_input)
	_reference_count = _label("", 13, MUTED)
	content.add_child(_reference_count)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 140
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	reference_rows = _vbox(6)
	reference_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(reference_rows)
	var close_button := _button("Tutup tabel  ·  Esc")
	close_button.pressed.connect(close_reference)
	content.add_child(close_button)


func _build_help() -> void:
	_help_dialog = AcceptDialog.new()
	_help_dialog.title = "Cara bermain Protein Forge"
	_help_dialog.theme = theme
	_help_dialog.dialog_text = "1. Baca tiga basa pada kodon mRNA.\n\n2. Pilih satu dari empat jawaban. Benar di percobaan pertama bernilai 100 poin; setelah salah bernilai 50 poin. Tabel kodon boleh dibuka kapan saja.\n\n3. Selesaikan enam ronde: lima asam amino dan satu kodon stop. Tidak ada batas waktu.\n\nRekor tersimpan di perangkat ini. Permainan memakai kode genetik standar dan rantai contoh."
	_help_dialog.get_label().autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_help_dialog.get_ok_button().text = "Siap, saya mengerti"
	add_child(_help_dialog)


func start_game(seed_value: int = -1) -> void:
	session.new_game(seed_value)
	_show_screen("game")
	_render_round()
	answer_buttons[0].grab_focus()


func choose_answer(code: String) -> void:
	if screen != "game":
		return
	var result: Dictionary = session.submit_answer(code)
	if not bool(result.get("accepted", false)):
		return
	for button in answer_buttons:
		if str(button.get_meta("code")) == code:
			button.disabled = true
			var color: Color = LIME if bool(result["correct"]) else DANGER
			button.add_theme_stylebox_override("disabled", _style(SOFT_PANEL, color, 8, 14))
			button.add_theme_color_override("font_disabled_color", color)
	if not bool(result["correct"]):
		_feedback.text = "Belum tepat. Coba lagi atau buka tabel kodon.\nJawaban yang tepat masih bernilai 50 poin."
		_feedback.add_theme_color_override("font_color", DANGER)
		return
	for button in answer_buttons:
		button.disabled = true
	_feedback.text = "Tepat! +%d poin\n%s" % [int(result["points"]), str(result["explanation"])]
	_feedback.add_theme_color_override("font_color", LIME)
	next_button.text = "Lihat hasil" if session.index == 5 else "Kodon berikutnya"
	next_button.show()
	_update_sidebar()
	next_button.grab_focus()


func next_round() -> void:
	if screen != "game" or not session.advance():
		return
	if session.finished:
		_finish_game()
	else:
		_render_round()
		answer_buttons[0].grab_focus()


func _render_round() -> void:
	var question: Dictionary = session.current_question()
	_round_label.text = "PESAN mRNA  5′ → 3′                          KODON %d / 6" % (session.index + 1)
	_clear(_codon_track)
	for index in range(session.questions.size()):
		var entry: Dictionary = session.questions[index]
		var color: Color = LIME if index == session.index else MUTED
		var chip := _chip(str(entry["codon"]), Vector2(0, 34), color, 14)
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_codon_track.add_child(chip)
	_clear(_current_codon)
	for base in str(question["codon"]):
		_current_codon.add_child(_chip(base, Vector2(64, 76), VIOLET if base == "A" else LIME, 40))
	_clear(_answer_grid)
	answer_buttons.clear()
	var options: Array = question["options"]
	for index in range(options.size()):
		var option: Dictionary = options[index]
		var code: String = str(option["code"])
		var button := _button("%d   %s   %s" % [index + 1, "STOP" if code == "*" else code, str(option["name"])])
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = 55
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.set_meta("code", code)
		button.pressed.connect(choose_answer.bind(code))
		_answer_grid.add_child(button)
		answer_buttons.append(button)
	_feedback.text = "Setiap jawaban adalah kesempatan belajar."
	_feedback.add_theme_color_override("font_color", MUTED)
	next_button.hide()
	_update_sidebar()


func _update_sidebar() -> void:
	score_label.text = "%03d" % session.score
	_best_label.text = "Rekor pribadi: %d" % _best_score
	_chain_count.text = "%d / 5 asam amino" % session.chain.size()
	_clear(_chain_row)
	for index in range(5):
		var code: String = session.chain[index] if index < session.chain.size() else "·"
		var chip := _chip(code, Vector2(30, 36), VIOLET if code != "·" else MUTED, 18)
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chip.tooltip_text = str(Session.AMINO_ACID_NAMES.get(code, "Belum dirakit"))
		_chain_row.add_child(chip)


func _finish_game() -> void:
	var is_record: bool = session.score > _best_score
	if is_record:
		_best_score = session.score
		var config := ConfigFile.new()
		config.set_value("game", "best_score", _best_score)
		config.save(SAVE_PATH)
	result_score_label.text = "%d / 600" % session.score
	_accuracy_label.text = "%d / 6 tepat pada percobaan pertama" % session.first_try
	_record_label.text = "Rekor baru. Terus bereksperimen!" if is_record else "Pemahaman tumbuh bersama setiap percobaan."
	_clear(_final_chain)
	for code in session.chain:
		var item := _vbox(8)
		item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_final_chain.add_child(item)
		item.add_child(_chip(code, Vector2(50, 54), VIOLET, 26))
		item.add_child(_label(str(Session.AMINO_ACID_NAMES[code]), 14, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	_show_screen("result")
	restart_button.grab_focus()


func open_reference() -> void:
	_reference_return_focus = get_viewport().gui_get_focus_owner()
	search_input.clear()
	filter_reference("")
	reference_dialog.popup_centered_clamped(Vector2i(640, 570), 0.92)
	search_input.grab_focus()


func filter_reference(query: String) -> void:
	_clear(reference_rows)
	var cleaned: String = query.strip_edges().to_lower()
	var entries: Array = Session.codon_entries()
	for entry in entries:
		var searchable: String = "%s %s %s" % [entry["codon"], entry["code"], entry["name"]]
		if not cleaned.is_empty() and not searchable.to_lower().contains(cleaned):
			continue
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 20)
		reference_rows.add_child(row)
		var codon := _label(str(entry["codon"]), 18, LIME)
		codon.custom_minimum_size.x = 90
		row.add_child(codon)
		var code := _label("STOP" if entry["code"] == "*" else str(entry["code"]), 16, VIOLET)
		code.custom_minimum_size.x = 65
		row.add_child(code)
		var amino := _label(str(entry["name"]), 16)
		amino.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(amino)
	_reference_count.text = "%d dari 64 kodon" % reference_rows.get_child_count()
	if reference_rows.get_child_count() == 0:
		_reference_count.text = "Tidak ada kodon yang cocok. Coba kata lain."


func close_reference() -> void:
	reference_dialog.hide()
	_restore_reference_focus()


func _restore_reference_focus() -> void:
	if is_instance_valid(_reference_return_focus) and _reference_return_focus.is_visible_in_tree():
		_reference_return_focus.grab_focus()


func _on_reference_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		close_reference()
		get_viewport().set_input_as_handled()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if reference_dialog.visible or _help_dialog.visible or screen != "game":
		return
	if event.ctrl_pressed or event.alt_pressed or event.meta_pressed:
		return
	var index: int = event.keycode - KEY_1
	if index >= 0 and index < answer_buttons.size() and not answer_buttons[index].disabled:
		choose_answer(str(answer_buttons[index].get_meta("code")))
		get_viewport().set_input_as_handled()


func _show_screen(name: String) -> void:
	screen = name
	_welcome.visible = name == "welcome"
	_game.visible = name == "game"
	_result.visible = name == "result"
	_page_scroll.scroll_vertical = 0


func _read_best_score() -> int:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return 0
	var saved: Variant = config.get_value("game", "best_score", 0)
	if saved is int and saved >= 0 and saved <= 600:
		return int(saved)
	return 0


func _clear(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()


func _vbox(gap: int) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", gap)
	return box


func _label(value: String, font_size: int = 16, color: Color = TEXT, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = alignment
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _button(value: String, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size.y = 46
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if primary:
		button.add_theme_stylebox_override("normal", _style(LIME, LIME, 8, 16))
		button.add_theme_stylebox_override("hover", _style(Color("d9ffa0"), LIME, 8, 16))
		button.add_theme_stylebox_override("pressed", _style(Color("b1dc68"), LIME, 8, 16))
		for state_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
			button.add_theme_color_override(state_name, BACKGROUND)
	return button


func _panel(color: Color = PANEL) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(color, LINE, 12, 18))
	return panel


func _chip(value: String, minimum: Vector2, color: Color, font_size: int = 20) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.custom_minimum_size = minimum
	chip.add_theme_stylebox_override("panel", _style(SOFT_PANEL, color.darkened(0.35), 7, 6))
	var label := _label(value, font_size, color, HORIZONTAL_ALIGNMENT_CENTER)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chip.add_child(label)
	return chip


func _style(color: Color, border: Color, radius: int, padding: int, border_size: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(border_size)
	style.set_corner_radius_all(radius)
	style.content_margin_left = padding
	style.content_margin_right = padding
	style.content_margin_top = padding
	style.content_margin_bottom = padding
	return style
