class_name KanjiItem
extends FilterableListItem

var draw_data: Array = []
var fills: Array = []

func get_text() -> String:
	if draw_data.is_empty():
		return text + " (no draw data)"
	return text
