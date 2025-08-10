extends Control

@onready var japanese_text: JapaneseText = $Panel/JapaneseText

func _ready() -> void:

	var phrases: Array[String] = [
		"駅{えき}の前{まえ}で待{ま}っています"
	]

	japanese_text.visible = false
	japanese_text.text = phrases[randi() % phrases.size()]

	#japanese_text.rendered.connect(_hide_random_kanji)
	japanese_text.hide_furigana_word_index = 0

	japanese_text.render_text()
	japanese_text.visible = true


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
