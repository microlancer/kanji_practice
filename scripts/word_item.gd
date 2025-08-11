class_name WordItem
extends FilterableListItem

var word: String = ""
var mastery: int = 0
var furigana: String = ""
var fills: Array = []

func get_text() -> String:
	return word + " (" + furigana + ")"

func is_valid() -> bool:
	var kanji_array: Array = PracticeDB.get_kanji_array(word)
	for kanji in kanji_array:
		if kanji not in PracticeDB.kanji:
			print("Kanji not in DB " + kanji)
			return false
		if PracticeDB.kanji[kanji].draw_data.is_empty():
			print("No draw data for " + kanji)
			return false
	if furigana == "":
		print("No furigana " + word)
		return  false
	return true
