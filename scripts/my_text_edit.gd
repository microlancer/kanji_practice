class_name MyTextEdit
extends TextEdit

func _ready() -> void:
	caret_blink = true
	add_theme_constant_override("caret_width", 3)
