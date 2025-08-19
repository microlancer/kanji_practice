class_name FillItem
extends FilterableListItem

var words: Array = []
var name: String = ""
var phrases: Array = []

func get_text() -> String:
	return name + ": " + ",".join(words)

func get_words_as_text() -> String:
	return ",".join(words)

func xis_valid() -> bool:

	if words.size() == 0:
		return false

	for word in words:
		if not JapaneseText.has_kanji(word):
			# Ignore words with no kanji
			continue
		if word in PracticeDB.words:
			var word_item: WordItem = WordItem.new()
			word_item.fills = []
			word_item.mastery_read = 0
			word_item.mastery_write = 0
			word_item.word = word
			word_item.furigana = PracticeDB.words[word].furigana
			if not word_item.is_valid:
				print("Word item is not valid: " + word)
				return false
		else:
			print("Word not found in PracticeDB: " + word)
			return false

	if not _fill_used_in_phrase():
		return false

	return true

func _fill_used_in_phrase() -> bool:
	for phrase in PracticeDB.phrases:
		if phrase.text.contains(name):
			return true
	return false
