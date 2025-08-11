class_name CommonControl
extends Control


func restore_button(wait_time: int, button: Button, text: String) -> void:
	var timer = Timer.new()
	timer.one_shot = true
	timer.autostart = true
	timer.wait_time = wait_time
	timer.timeout.connect(restore_button_timeout.bind(timer, text, button))
	add_child(timer)

func restore_button_timeout(timer: Timer, text: String, button: Button) -> void:
	button.text = text
	button.remove_theme_color_override("font_color")
	button.remove_theme_color_override("font_pressed_color")
	button.remove_theme_color_override("font_focus_color")
	button.remove_theme_color_override("font_hover_color")
	button.remove_theme_color_override("font_disabled_color")
	timer.queue_free()

func set_button_color(button: Button, color: Color) -> void:
	button.add_theme_color_override("font_color", color)
	button.add_theme_color_override("font_pressed_color", color)
	button.add_theme_color_override("font_focus_color", color)
	button.add_theme_color_override("font_hover_color", color)
	button.add_theme_color_override("font_disabled_color", color)

func button_error(button: Button, error_text: String) -> void:
	set_button_color(button, Color.RED)
	var original_text = button.text
	button.text = error_text
	restore_button(3, button, original_text)

func button_success(button: Button, success_text: String) -> void:
	set_button_color(button, Color.GREEN)
	var original_text = button.text
	button.text = success_text
	restore_button(3, button, original_text)
