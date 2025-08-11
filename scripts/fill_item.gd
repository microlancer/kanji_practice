class_name FillItem
extends FilterableListItem

var words: Array = []
var name: String = ""
var phrases: Array = []

func get_text() -> String:
	return name + ": " + ",".join(words)

func get_words_as_text() -> String:
	return ",".join(words)

func is_valid() -> bool:

	if words.size() == 0:
		return false

	for word in words:
		if not JapaneseText.has_kanji(word):
			# Ignore words with no kanji
			continue
		if word in PracticeDB.words:
			var word_item: WordItem = WordItem.new()
			word_item.furigana = PracticeDB.words[word].furigana
			if not word_item.is_valid():
				return false
		else:
			return false

	return true
