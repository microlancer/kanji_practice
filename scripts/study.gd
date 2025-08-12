extends Control

@onready var japanese_text: JapaneseText = $Panel/JapaneseText

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

func _on_db_loaded() -> void:
	_start_study()

func _start_study() -> void:

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
	var tag: String = "<>"

	print("Random fill: " + random_fill.name)

	tag = "<"+random_fill.name+">"

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

	var fills: Array = PracticeDB.extract_fills(random_phrase)

	var index = 0
	var hide_index = 0
	for fill in fills:
		if fill == random_fill.name:
			var furigana = PracticeDB.words[random_word.word].furigana
			random_phrase = random_phrase.replace(tag, "["+random_word.word+"]{"+furigana+"}")
			hide_index = index
			index += 1
		else:
			var fill_word = PracticeDB.fills[fill].words.pick_random()
			if JapaneseText.has_kanji(fill_word):
				var furigana = PracticeDB.words[fill_word].furigana
				random_phrase = random_phrase.replace("<"+fill+">", "["+fill_word+"]{"+furigana+"}")
				index += 1
			else:
				random_phrase = random_phrase.replace("<"+fill+">", fill_word)



	print("Random phrase: " + random_phrase)

	if randi() % 2 == 0:
		print("Random Hiding furigana")
		japanese_text.hide_furigana_word_index = hide_index
		japanese_text.hide_kanji_word_index = japanese_text.NO_HIDE
	else:
		print("Random Hiding kanji-containing word")
		japanese_text.hide_kanji_word_index = hide_index
		japanese_text.hide_furigana_word_index = japanese_text.NO_HIDE

	japanese_text.set_text(random_phrase)

	await japanese_text.rendered


func _hide_random_kanji() -> void:
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
