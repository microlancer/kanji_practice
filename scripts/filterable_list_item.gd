class_name FilterableListItem
extends Object

var text: String = ""
var visible_index: int = 0
var real_index: int = 0
#var data: Dictionary = {}

func get_text() -> String:
	return text

func is_valid() -> bool:
	return true
