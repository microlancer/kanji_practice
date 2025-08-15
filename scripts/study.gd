extends Control


signal jump_to_phrases
@onready var japanese_text: JapaneseText = $Panel/JapaneseText
@onready var _draw_panel: DrawPanel = $DrawPanel
var _expected_strokes: Array = []
var _expected_word: String = ""
var _mastery_word: String = ""
var _mastery_type: PracticeDB.MasteryType
var _expected_phrase: String = ""
var _made_mistake: bool = false
var _is_due: bool = false
#var _strokes_drawn: Array = []
var _char_index: int = 0 # which character we're writing
#var _char_stroke_index: int = 0 # which stroke of the current character
var _check_due_timer: Timer

func _ready() -> void:
	$DrawPanel.disable()
	japanese_text.visible = false
	japanese_text.text = ""
	#$DrawPanel.disable()

	#japanese_text.rendered.connect(_hide_random_kanji)
	#japanese_text.hide_furigana_word_index = 0

	japanese_text.render_text()
	japanese_text.visible = true

	PracticeDB.db_loaded.connect(_on_db_loaded)

	$Answer.text = ""



	_check_due_timer = Timer.new()
	_check_due_timer.autostart = false
	_check_due_timer.one_shot = false
	_check_due_timer.wait_time = 3
	_check_due_timer.timeout.connect(_on_check_due_timer)
	add_child(_check_due_timer)

func _on_check_due_timer() -> void:

	var valid_data: Dictionary = PracticeDB.get_valid_data()

	if valid_data.words.is_empty():
		_set_error("No valid words")
		return

	var total_due: int = PracticeDB.get_due_count(valid_data.words)
	print("Checking total due: " + str(total_due))

	if total_due <= 0:
		_check_due_timer.start()
		return



	_start_study()

func _on_db_loaded() -> void:
	_start_study()

func _set_error(e: String) -> void:
	print("ERROR: " + e)
	$Answer.text = "[color=red]" + e + "[/color]"

func _start_study() -> void:

	$Answer.text = ""
	$TryAgain.visible = false
	$ShowAnswer.visible = false
	_expected_strokes = []
	_expected_word = ""
	_char_index = 0
	_made_mistake = false
	_is_due = false
	_check_due_timer.stop()

	var valid_data: Dictionary = PracticeDB.get_valid_data()

	if valid_data.words.is_empty():
		_set_error("No valid words")
		return

	#var valid_words: Array = []

	#for word in PracticeDB.words:
		#var word_item: WordItem = WordItem.new()
		#word_item.word = word
		#word_item.furigana = PracticeDB.words[word].furigana
		#if word_item.is_valid():
			#valid_words.append(word_item)
#
	#if valid_words.is_empty():
		#print("No valid words")
		#return

	var random_word: String
	var random_mastery_type: PracticeDB.MasteryType
	if false:
		random_word = valid_data.words.pick_random()
	else:
		var due: Dictionary = PracticeDB.select_due(valid_data.words)
		random_word = due.word
		random_mastery_type = due.mastery_type
		if due.due_seconds < 0:
			_is_due = false # negative value means it's not yet due
		else:
			_is_due = true # postive value means "now minus due" is large

	var total_due: int = PracticeDB.get_due_count(valid_data.words)

	print("Total due: " + str(total_due))
	$Due.text = str(total_due) + " due"

	if total_due == 0:
		$Answer.text = "[color=lightgreen]✓[/color] Done for now"
		$DrawPanel.enabled = false
		$Panel/JapaneseText.text = ""
		$Panel/JapaneseText.set_text("")
		_check_due_timer.start()
		return

	print("Random word: " + random_word)

	# Select a valid fill that uses the randomly picked word
	var valid_fills_for_word: Dictionary = {} # de-dup fills

	for fill_name in valid_data.fills:
		var fill: Dictionary = PracticeDB.fills[fill_name]
		if fill.words.has(random_word):
			valid_fills_for_word[fill_name] = true

	if valid_fills_for_word.is_empty():
		_set_error("No valid fills")
		return

	var random_fill_name: String = valid_fills_for_word.keys().pick_random()

	print("Random fill: " + random_fill_name)

	# Select a valid phrase that uses the randomly picked fill
	var valid_phrases_for_fill: Array = []

	for phrase in valid_data.phrases:
		if phrase.contains(random_fill_name):
			valid_phrases_for_fill.append(phrase)

	if valid_phrases_for_fill.is_empty():
		_set_error("No valid phrase")
		return

	var random_phrase: String = valid_phrases_for_fill.pick_random()

	_expected_phrase = random_phrase

	var mode: String = "hide_furigana"

	if randi() % 2 == 0:
		mode = "hide_furigana"
	else:
		mode = "hide_kanji"

	if random_mastery_type == PracticeDB.MasteryType.MASTERY_READ:
		mode = "hide_furigana"
	else:
		mode = "hide_kanji"

	# replace for quiz

	var fills: Array = PracticeDB.extract_fills(random_phrase)
	var furigana: String = ""
	var index = 0
	var hide_index = 0
	for fill_name in fills:
		if fill_name == random_fill_name:
			furigana = PracticeDB.words[random_word].furigana
			random_phrase = random_phrase.replace(fill_name, "["+random_word+"]{"+furigana+"}")
			hide_index = index
			index += 1
		else:
			var fill_word = PracticeDB.fills[fill_name].words.pick_random()
			if JapaneseText.has_kanji(fill_word):
				var tmp_furigana = PracticeDB.words[fill_word].furigana
				if mode == "hide_furigana":
					# if we're only hiding the furigana, we will quiz on
					# only the kanji part, because hiragana is already shown
					# TODO: not implemented, because there can be multiple
					# kanji in the word which needs to be handled
					random_phrase = random_phrase.replace(fill_name, "["+fill_word+"]{"+tmp_furigana+"}")
				else:
					random_phrase = random_phrase.replace(fill_name, "["+fill_word+"]{"+tmp_furigana+"}")
				index += 1
			else:
				random_phrase = random_phrase.replace(fill_name, fill_word)

	print("Random phrase with furigana: " + random_phrase)

	if mode == "hide_furigana":
		print("Random Hiding furigana")
		_expected_strokes = _get_strokes_for_word(furigana)
		_expected_word = furigana
		_mastery_type = PracticeDB.MasteryType.MASTERY_READ
		_mastery_word = random_word
		japanese_text.hide_furigana_word_index = hide_index
		japanese_text.hide_kanji_word_index = japanese_text.NO_HIDE
		#$Answer.text = "furigana"
		#$Answer.self_modulate.a = 0.5
	else:
		print("Random Hiding kanji-containing word")
		_expected_strokes = _get_strokes_for_word(random_word)
		_expected_word = random_word
		_mastery_type = PracticeDB.MasteryType.MASTERY_WRITE
		_mastery_word = random_word
		japanese_text.hide_kanji_word_index = hide_index
		japanese_text.hide_furigana_word_index = japanese_text.NO_HIDE
		#$Answer.text = "kanji word"
		#$Answer.self_modulate.a = 0.5

	print("Expected word: " + _expected_word)
	print("Expected strokes: " + str(_expected_strokes.size()))

	japanese_text.set_text(random_phrase)
	#print({"exp":_expected_strokes})

	$DrawPanel.enable()

	await japanese_text.rendered


func x_hide_random_kanji() -> void:
	print("hide")

	#japanese_text.render_text()

	var kanji_words: Array[Dictionary] = japanese_text.get_kanji_words()

	print({"ww":kanji_words})

	japanese_text.visible = true
#	var hide_kanji_word_index: int = randi() % kanji_words.size()

#	japanese_text.render_text(hide_kanji_word_index)

	# Extract kanji

	# Randomly select one kanji word for quiz

	# For other kanji, show furigana unless > level 2.


func _on_next_pressed() -> void:
	_start_study()


func _on_clear_pressed() -> void:
	_draw_panel.clear()
	#_strokes_drawn = []



func _loosely_matches(a: String, b: String) -> bool:

	if a == b:
		return true
	elif a == "DR" and b == "R":
		return true
	elif a == "DL" and b == "L":
		return true
	elif a == "DR" and b == "D":
		return true
	elif a == "DL" and b == "D":
		return true
	elif a == "R" and b == "DR":
		return true
	elif a == "L" and b == "DL":
		return true
	elif a == "R" and b == "UR":
		return true
	elif a == "U" and b == "UL":
		return true
	elif a == "U" and b == "UR":
		return true
	elif a == "D" and b == "R":
		return true
	elif a == "L" and b == "D":
		return true
	elif a == "R" and b == "D":
		return true

	return false

func xxx_on_draw_panel_stroke_drawn(strokeIndex: int, direction: String) -> void:
	print({"i":strokeIndex,"d":direction})
	#print(_expected_strokes)
	#_strokes_drawn.append(direction)

	var a: String = _expected_strokes[_char_index][strokeIndex]
	var b: String = direction

	if _loosely_matches(a, b) or _loosely_matches(b, a):
		# correct
		if strokeIndex == _expected_strokes[_char_index].size() - 1:
			# end of character success
			print("End of character success")
			_show_answer_progress()
			_char_index += 1
			_draw_panel.clear()
			if _char_index == _expected_strokes.size():
				print("End of word, move to next quiz")
				$Sound2.play()
				_start_study()
				return
			else:
				print("More characters remaining")
				$Sound1.play()
		else:
			print("Not end of character, keep going")
			# not end of character yet, keep going
			pass
	else:
		# incorrect stroke
		$Answer.text = "incorrect"
		_draw_panel.brush_color = Color.RED
		#_draw_panel._requested_refresh = true
		_draw_panel.disable()
		$TryAgain.visible = true
		$ShowAnswer.visible = true

	#print(_strokes_drawn)

func _show_answer_progress() -> void:
	$Answer.text = ""
	var i = 0
	for c in _expected_word:
		if i <= _char_index:
			$Answer.text += c
		i += 1
	$Answer.text += "[color=yellow]_[/color]"

func _get_strokes_for_word(word: String) -> Array:
	var strokes: Array = []
	for c in word:
		strokes.append(_get_strokes_for_char(c))
	return strokes

func _get_strokes_for_char(c: String) -> Array:
	var draw_data_encoded
	if JapaneseText.is_kanji(c):
		draw_data_encoded = PracticeDB.get_draw_data_for_kanji(c)
	else:
		# kana
		draw_data_encoded = PracticeDB.get_draw_data_for_kana(c)
	var draw_data = PracticeDB.decode_all_strokes(draw_data_encoded)
	return draw_data


func _on_try_again_pressed() -> void:
	$Answer.text = ""
	_char_index = 0
	_draw_panel.clear()
	_draw_panel.brush_color = Color.WHITE
	_draw_panel.enable()
	$TryAgain.visible = false
	$ShowAnswer.visible = false


func _on_show_answer_pressed() -> void:
	$Answer.text = _expected_word


func _on_edit_pressed() -> void:
	PracticeDB.filter_phrases = _expected_phrase
	jump_to_phrases.emit()


func _on_draw_panel_stroke_drawn_raw(strokeIndex: int, points: Array) -> void:
	#print(points)
	print("normalizing")
	var sig = StrokeUtils.process_stroke(points, 32, 0.02, true)
	#print(sig)

	var reference_sig: Dictionary = _expected_strokes[_char_index][strokeIndex]

	var similarity: float = StrokeUtils.compare_strokes2(reference_sig, sig, true, 0.25)
	print("Comparing signatures, similarity: " + str(similarity))
	# compare_strokes returns a 0.0 (identical) to 1.0 (max difference) range
	if similarity < 0.6:
		print("Stroke is a match")
		# correct
		if strokeIndex == _expected_strokes[_char_index].size() - 1:
			# end of character success
			print("End of character success")
			_show_answer_progress()
			_char_index += 1
			_draw_panel.clear()
			if _char_index == _expected_strokes.size():
				print("End of word, move to next quiz")
				$Sound2.play()
				if not _made_mistake and _is_due:
					PracticeDB.increment_mastery_for_word(_mastery_word, _mastery_type)
				elif not _made_mistake and not _is_due:
					PracticeDB.postpone_due_for_word(_mastery_word, _mastery_type)
				else:
					PracticeDB.reset_mastery_for_word(_mastery_word, _mastery_type)
					_made_mistake = false
				_start_study()
				return
			else:
				print("More characters remaining")
				$Sound1.play()
		else:
			print("Not end of character, keep going")
			# not end of character yet, keep going
			pass
	else:
		# incorrect stroke
		$Answer.text = "incorrect"
		$Sound3.play()
		_draw_panel.brush_color = Color.RED
		#_draw_panel._requested_refresh = true
		_draw_panel.disable()
		_made_mistake = true
		$TryAgain.visible = true
		$ShowAnswer.visible = true
