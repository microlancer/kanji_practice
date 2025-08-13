extends Control


signal jump_to_phrases
@onready var japanese_text: JapaneseText = $Panel/JapaneseText
@onready var _draw_panel: DrawPanel = $DrawPanel
var _expected_strokes: Array = []
var _expected_word: String = ""
var _expected_phrase: String = ""
#var _strokes_drawn: Array = []
var _char_index: int = 0 # which character we're writing
#var _char_stroke_index: int = 0 # which stroke of the current character

func _ready() -> void:

	var phrases: Array[String] = [
		"駅{えき}の前{まえ}で待{ま}っています"
	]

	japanese_text.visible = false
	japanese_text.text = phrases[randi() % phrases.size()]

	#japanese_text.rendered.connect(_hide_random_kanji)
	#japanese_text.hide_furigana_word_index = 0

	japanese_text.render_text()
	japanese_text.visible = true

	PracticeDB.db_loaded.connect(_on_db_loaded)

	$Answer.text = ""

func _on_db_loaded() -> void:
	_start_study()

func _start_study() -> void:

	$Answer.text = ""
	$TryAgain.visible = false
	$ShowAnswer.visible = false
	_expected_strokes = []
	_expected_word = ""
	_char_index = 0

	var valid_words: Array = []

	for word in PracticeDB.words:
		var word_item: WordItem = WordItem.new()
		word_item.word = word
		word_item.furigana = PracticeDB.words[word].furigana
		if word_item.is_valid():
			valid_words.append(word_item)

	if valid_words.is_empty():
		print("No valid words")
		return

	var random_word: WordItem = valid_words.pick_random()

	print("Random word: " + random_word.word)

	var valid_fills: Array = []

	for fill in PracticeDB.fills:
		var fill_item: FillItem = FillItem.new()
		fill_item.words = PracticeDB.fills[fill].words
		fill_item.name = fill
		if fill_item.is_valid() and fill_item.words.has(random_word.word):
			valid_fills.append(fill_item)

	if valid_fills.is_empty():
		print("No valid fills")
		return

	var random_fill: FillItem = valid_fills.pick_random()
	var tag: String = ""

	print("Random fill: " + random_fill.name)

	tag = random_fill.name

	var valid_phrases: Array = []
	for phrase in PracticeDB.phrases:
		var phrase_item: PhraseItem = PhraseItem.new()
		phrase_item.text = phrase
		if phrase_item.is_valid() and phrase.contains(tag):
			valid_phrases.append(phrase)

	if valid_phrases.is_empty():
		print("No valid phrase")
		return

	var random_phrase: String = valid_phrases.pick_random()

	_expected_phrase = random_phrase

	var mode: String = "hide_furigana"

	if randi() % 2 == 0:
		mode = "hide_furigana"
	else:
		mode = "hide_kanji"

	var fills: Array = PracticeDB.extract_fills(random_phrase)
	var furigana: String = ""
	var index = 0
	var hide_index = 0
	for fill in fills:
		if fill == random_fill.name:
			furigana = PracticeDB.words[random_word.word].furigana
			random_phrase = random_phrase.replace(tag, "["+random_word.word+"]{"+furigana+"}")
			hide_index = index
			index += 1
		else:
			var fill_word = PracticeDB.fills[fill].words.pick_random()
			if JapaneseText.has_kanji(fill_word):
				var tmp_furigana = PracticeDB.words[fill_word].furigana
				if mode == "hide_furigana":
					# if we're only hiding the furigana, we will quiz on
					# only the kanji part, because hiragana is already shown
					# TODO: not implemented, because there can be multiple
					# kanji in the word which needs to be handled
					random_phrase = random_phrase.replace(fill, "["+fill_word+"]{"+tmp_furigana+"}")
				else:
					random_phrase = random_phrase.replace(fill, "["+fill_word+"]{"+tmp_furigana+"}")
				index += 1
			else:
				random_phrase = random_phrase.replace(fill, fill_word)



	print("Random phrase: " + random_phrase)



	if mode == "hide_furigana":
		print("Random Hiding furigana")
		_expected_strokes = _get_strokes_for_word(furigana)
		_expected_word = furigana
		japanese_text.hide_furigana_word_index = hide_index
		japanese_text.hide_kanji_word_index = japanese_text.NO_HIDE
		#$Answer.text = "furigana"
		#$Answer.self_modulate.a = 0.5
	else:
		print("Random Hiding kanji-containing word")
		_expected_strokes = _get_strokes_for_word(random_word.word)
		_expected_word = random_word.word
		japanese_text.hide_kanji_word_index = hide_index
		japanese_text.hide_furigana_word_index = japanese_text.NO_HIDE
		#$Answer.text = "kanji word"
		#$Answer.self_modulate.a = 0.5

	japanese_text.set_text(random_phrase)
	print({"exp":_expected_strokes})

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

func _on_draw_panel_stroke_drawn(strokeIndex: int, direction: String) -> void:
	print({"i":strokeIndex,"d":direction})
	print(_expected_strokes)
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
	if JapaneseText.is_kanji(c):
		return PracticeDB.kanji[c].draw_data
	return PracticeDB.get_draw_data_for_kana(c)


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
