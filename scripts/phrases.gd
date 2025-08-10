extends Control

const NONE = -1
signal jump_to_lists

@onready var phrase_list: FilterableList = $FilterableList

var _editing_index: int = NONE

func _ready() -> void:

	for i in PracticeDB.phrases:
		phrase_list.all_items.append(i)

	phrase_list.refresh_item_list()

	phrase_list.item_selected.connect(_on_phrase_selected)

	$Save.disabled = true
	$Delete.visible = false
	$Lists.visible = false

func _phrase_contains_lists(phrase: String) -> bool:
	if phrase.contains("<") and phrase.contains(">"):
		return true
	return false

func _on_phrase_selected(index: int) -> void:
	print("Picked " + str(index))
	var phrase = PracticeDB.phrases[index]
	_editing_index = index
	$Phrase.text = phrase
	$Delete.visible = true
	$Lists.visible = true

	if _phrase_contains_lists(phrase):
		$Lists.disabled = false
	else:
		$Lists.disabled = true

	$Save.text = "Save"
	$Save.disabled = true


func _set_button_color(button: Button, color: Color) -> void:
	button.add_theme_color_override("font_color", color)
	button.add_theme_color_override("font_pressed_color", color)
	button.add_theme_color_override("font_focus_color", color)
	button.add_theme_color_override("font_hover_color", color)

func _on_save_pressed() -> void:

	var phrase = $Phrase.text

	if phrase == "":
		return

	if PracticeDB.phrases.has(phrase):
		$Save.text = "Already exists"
		_set_button_color($Save, Color.RED)
		_restore_button(2, $Save, "Save")
		return


	if _editing_index == NONE:
		$Save.text = "Added!"
		phrase_list.all_items.append(phrase)
		PracticeDB.phrases.append(phrase)
		print(phrase_list.all_items)
		_editing_index = phrase_list.all_items.size() - 1
	else:
		phrase_list.all_items[_editing_index] = phrase
		PracticeDB.phrases[_editing_index] = phrase
		$Save.text = "Updated!"

	if _phrase_contains_lists(phrase):
		$Lists.disabled = false
	else:
		$Lists.disabled = true

	$Delete.visible = true
	$Lists.visible = true
	phrase_list.refresh_item_list()
	phrase_list.item_list.select(_editing_index)

	$Save.disabled = true
	_restore_button(2, $Save, "Save")


func _restore_button(wait_time: int, button: Button, text: String, color: Color = Color.WHITE) -> void:
	var timer = Timer.new()
	timer.one_shot = true
	timer.autostart = true
	timer.wait_time = wait_time
	timer.timeout.connect(_restore_button_timeout.bind(timer, button, color))
	add_child(timer)

func _restore_button_timeout(timer: Timer, button: Button, color: Color) -> void:
	button.text = "Save"
	_set_button_color(button, color)
	timer.queue_free()


func _on_new_pressed() -> void:
	$Phrase.text = ""
	phrase_list.item_list.deselect_all()
	_editing_index = NONE
	$Save.text = "Add phrase"
	$Save.disabled = true
	$Lists.visible = false
	$Delete.visible = false


func _on_phrase_text_changed() -> void:
	$Save.disabled = false

func _get_lists_in_phrase(phrase: String) -> Array:

	var regex := RegEx.new()
	regex.compile("<(.*?)>")

	var matches := []
	for result in regex.search_all(phrase):
		# result.get_string(1) is the first capture group (.*?) from the pattern
		matches.append(result.get_string(1))

	return matches

func _create_lists_if_missing(list_names: Array) -> void:
	print("Creating if missing")
	for i in list_names:
		if not PracticeDB.lists.has(i):
			print("Adding to lists: " + i)
			PracticeDB.lists[i] = {
				"words": [],
				"phrases": [_editing_index],
			}
		else:
			print("Already exists: " + i)

func _on_lists_pressed() -> void:
	var phrase: String = phrase_list.all_items[_editing_index]
	var lists_in_phrase: Array = _get_lists_in_phrase(phrase)
	_create_lists_if_missing(lists_in_phrase)
	PracticeDB.filter_lists = "|".join(lists_in_phrase)
	print(lists_in_phrase)

	jump_to_lists.emit()
