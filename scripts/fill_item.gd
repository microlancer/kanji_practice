class_name FillItem
extends FilterableListItem

var words: Array = []
var name: String = ""
var phrases: Array = []

func get_text() -> String:
	return name + ": " + ",".join(words)

func get_words_as_text() -> String:
	return ",".join(words)
