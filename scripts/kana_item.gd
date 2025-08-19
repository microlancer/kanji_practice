class_name KanaItem
extends FilterableListItem

var draw_data: String = ""
var fills: Array = []

func get_text() -> String:
	if draw_data == "":
		return text + " (no draw data)"
	return text + " (" + str(draw_data.length()) + " bytes)"

#func is_valid() -> bool:
#	return draw_data != ""
