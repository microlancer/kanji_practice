extends CommonControl

const NONE = -1
signal jump_to_fills

@onready var _phrase_list: FilterableList = $FilterableList

var _editing_real_index: int = NONE

func _ready() -> void:

	_phrase_list.item_selected.connect(_on_phrase_selected)

	init_from_db()

	$Phrase.text = ""
	$Save.disabled = true
	$Delete.visible = false
	$Fills.visible = false
	$Save.text = "Add phrase"

func init_from_db() -> void:
	var all_phrases: Array[FilterableListItem] = []

	for phrase in PracticeDB.phrases:
		var phrase_item: PhraseItem = PhraseItem.new()
		phrase_item.text = phrase
		print({"phrase_item":phrase_item})
		all_phrases.append(phrase_item)

	_phrase_list.init_all_items(all_phrases)
	init_filter()

func init_filter() -> void:
	_phrase_list.filter_edit.text = PracticeDB.filter_phrases
	_phrase_list.apply_filter()

func _phrase_contains_fills(phrase: String) -> bool:
	if phrase.contains("<") and phrase.contains(">"):
		return true
	return false

func _on_phrase_selected(item: FilterableListItem) -> void:
	print("Picked " + str(item.real_index))
	var phrase = PracticeDB.phrases[item.real_index]
	_editing_real_index = item.real_index
	$Phrase.text = phrase
	$Delete.visible = true
	$Fills.visible = true

	if _phrase_contains_fills(phrase):
		$Fills.disabled = false
	else:
		$Fills.disabled = true

	$Save.text = "Save changes"
	$Save.disabled = true

func _on_save_pressed() -> void:

	var phrase = $Phrase.text

	if phrase == "":
		return

	if PracticeDB.phrases.has(phrase):
		button_error($Save, "Already exists")
		return

	if _editing_real_index == NONE:
		_add_new_phrase(phrase)
	else:
		_update_existing_phrase(phrase)

	if _phrase_contains_fills(phrase):
		$Fills.disabled = false
	else:
		$Fills.disabled = true

	$Delete.visible = true
	$Fills.visible = true
	_phrase_list.apply_filter()

	_phrase_list.select_by_real_index(_editing_real_index)

	if _phrase_list.is_visible_by_real_index(_editing_real_index):
		pass
		$Save.text = "Save changes"
	else:
		_editing_real_index = NONE
		$Save.text = "Add phrase"

	$Save.disabled = true

	PracticeDB.db_changed.emit()


func _add_new_phrase(phrase: String) -> void:
	#button_success($Save, "Added")
	var phrase_item: PhraseItem = PhraseItem.new()
	phrase_item.text = phrase
	_phrase_list.add_item(phrase_item)
	PracticeDB.phrases.append(phrase)
	_editing_real_index = PracticeDB.phrases.size() - 1

func _update_existing_phrase(phrase: String) -> void:
	var phrase_item: PhraseItem = _phrase_list.get_item_by_real_index(_editing_real_index)
	phrase_item.text = phrase
	PracticeDB.phrases[_editing_real_index] = phrase
	#button_success($Save, "Updated")

func _on_new_pressed() -> void:
	$Phrase.text = ""
	_phrase_list.deselect_all()
	_editing_real_index = NONE
	$Save.text = "Add phrase"
	$Save.disabled = true
	$Fills.visible = false
	$Delete.visible = false


func _on_phrase_text_changed() -> void:
	$Save.disabled = false

func _get_lists_in_phrase(phrase: String) -> Array:
	return PracticeDB.extract_fills(phrase)

func _create_fills_if_missing(list_names: Array) -> void:
	print("Creating if missing")
	var added: bool = false
	for i in list_names:
		if not PracticeDB.fills.has(i):
			print("Adding to fills: " + i)
			PracticeDB.fills[i] = {
				"words": [],
				"phrases": [_editing_real_index],
			}
			added = true
		else:
			print("Already exists: " + i)

	if added:
		PracticeDB.db_changed.emit()

func _on_fills_pressed() -> void:
	#var phrase: String = phrase_list.all_items[_editing_real_index]
	var phrase = PracticeDB.phrases[_editing_real_index]
	var fills_in_phrase: Array = _get_lists_in_phrase(phrase)
	_create_fills_if_missing(fills_in_phrase)
	PracticeDB.filter_fills = "|".join(fills_in_phrase)
	print(fills_in_phrase)

	jump_to_fills.emit()
