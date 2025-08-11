class_name WordItem
extends FilterableListItem

var word: String = ""
var mastery: int = 0
var furigana: String = ""
var fills: Array = []

func get_text() -> String:
	return word + " (" + furigana + ")"
