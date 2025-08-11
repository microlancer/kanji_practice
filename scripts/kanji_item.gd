class_name KanjiItem
extends FilterableListItem

var kanji: String = ""
var draw_data: Array = []
var fills: Array = []

func get_text() -> String:
	if not draw_data.is_empty():
		return kanji + " (no draw data)"
	return kanji
