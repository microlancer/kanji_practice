class_name Common
extends Control

func _restore_button(wait_time: int, button: Button, text: String, color: Color = Color.WHITE) -> void:
	var timer = Timer.new()
	timer.one_shot = true
	timer.autostart = true
	timer.wait_time = wait_time
	timer.timeout.connect(_restore_button_timeout.bind(timer, text, button, color))
	add_child(timer)

func _restore_button_timeout(timer: Timer, text: String, button: Button, color: Color) -> void:
	button.text = text
	PracticeDB.set_button_color(button, color)
	timer.queue_free()
