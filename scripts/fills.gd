extends CommonControl

const NONE = -1
signal jump_to_words
@onready var _fills_list: FilterableList = $FilterableList
var _editing_real_index: int = NONE
var _editing_original_name: String = ""

func _ready() -> void:
	_fills_list.item_selected.connect(_on_item_selected)
	_fills_list.filter_changed.connect(_on_filter_changed)
	init_from_db()
	$Save.disabled = true
	$Delete.visible = false
	$Words.visible = false

func init_from_db() -> void:
	var all_items: Array[FilterableListItem] = []
	for fill_name in PracticeDB.fills:
		var fill: FillItem = FillItem.new()
		print(PracticeDB.fills[fill_name])
		fill.name = fill_name
		fill.words = PracticeDB.fills[fill_name].words
		fill.phrases = PracticeDB.fills[fill_name].phrases
		fill.is_valid = PracticeDB.fills[fill_name].is_valid
		all_items.append(fill)

	_fills_list.init_all_items(all_items)
	init_filter()


func init_filter() -> void:
	_fills_list.filter_edit.text = PracticeDB.filter_fills
	_fills_list.apply_filter()
	$ListOfWords.text = ""
	$NameEdit.text = ""

	if _fills_list.filter_edit.text != "":
		_fills_list.select_by_visible_index(0)

func _on_item_selected(item: FilterableListItem) -> void:
	var fill: FillItem = item as FillItem
	print({"selected": { "visible": fill.visible_index, "real": fill.real_index}})
	_editing_real_index = fill.real_index
	_editing_original_name = fill.name
	$NameEdit.text = fill.name
	$ListOfWords.text = fill.get_words_as_text()
	$Delete.visible = true
	$Words.visible = true


	if _list_contains_kanji_words(fill.words):
		$Words.disabled = false
	else:
		$Words.disabled = true

	$Save.text = "Save changes"
	$Save.disabled = true

func _on_filter_changed(filter: String) -> void:
	PracticeDB.filter_fills = filter
	$ListOfWords.text = ""
	$NameEdit.text = ""
	$Delete.visible = false
	$Words.visible = false
	$Save.disabled = true
	_editing_real_index = NONE

func _list_contains_kanji_words(words: Array) -> bool:
	for i in words:
		if JapaneseText.has_kanji(i):
			return true
	return false

func _list_get_kanji_words(words: Array) -> Array:
	var kanji_words: Array = []
	for i in words:
		if JapaneseText.has_kanji(i):
			kanji_words.append(i)
	return kanji_words

func _on_save_pressed() -> void:
	var fill_name = $NameEdit.text
	var words = $ListOfWords.text
	var words_array = $ListOfWords.text.split(",")

	if words == "":
		button_error($Save, "Words required")
		return

	if fill_name == "":
		button_error($Save, "Name required")
		return

	if _editing_real_index == NONE:
		_save_new_fill(fill_name, words_array)
	else:
		_update_existing_fill(fill_name, words_array)

	var fill_item: Dictionary = PracticeDB.fills[fill_name]

	if _list_contains_kanji_words(fill_item.words):
		$Words.disabled = false
	else:
		$Words.disabled = true

	$Delete.visible = true
	print({"words":PracticeDB.fills[fill_name].words})

	if not PracticeDB.fills[fill_name].words.is_empty():
		$Words.visible = true
	else:
		print("No words")
		$Words.visible = false

	# if the edited item is on the filtered list, try to select it
	_fills_list.select_by_real_index(_editing_real_index)

	if _fills_list.is_visible_by_real_index(_editing_real_index):
		_editing_original_name = fill_name
		$Save.text = "Save changes"
	else:
		_editing_original_name = ""
		_editing_real_index = NONE

	$Save.disabled = true
	#restore_button(2, $Save, "Save changes")

	PracticeDB.mark_valid_items()
	PracticeDB.db_changed.emit()

func _save_new_fill(fill_name: String, words_array: Array) -> void:
	#$Save.text = "Added!"
	var new_fill: FillItem = FillItem.new()
	new_fill.name = fill_name
	new_fill.words = words_array
	_fills_list.add_item(new_fill)

	PracticeDB.fills[new_fill.name] = {
		"words": new_fill.words,
		"phrases": [] # TODO
	}

	_editing_real_index = PracticeDB.fills.size() - 1

func _update_existing_fill(fill_name: String, words_array: Array) -> void:
	#$Save.text = "Updated!"
	if fill_name != _editing_original_name:
		# Name was changed, erase old name
		PracticeDB.fills.erase(_editing_original_name)
		# Store into new name
		PracticeDB.fills[fill_name] = {
			"words": [],
			"phrases": []
		}

	PracticeDB.fills[fill_name].words = words_array
	PracticeDB.fills[fill_name].phrases = [] # TODO
	var fill: FillItem = _fills_list.get_item_by_real_index(_editing_real_index)
	fill.name = fill_name
	fill.words = words_array
	fill.phrases = [] # TODO
	_fills_list.apply_filter()

func _create_words_if_missing(words: Array) -> void:
	print("Creating if missing")
	var added: bool = false
	for i in words:
		if not PracticeDB.words.has(i):
			print("Adding to words: " + i)
			PracticeDB.words[i] = {
				"furigana": "",
				"mastery": 0,
				"fills": [], #TODO
			}
			added = true
		else:
			print("Already exists: " + i)

	if added:
		PracticeDB.mark_valid_items()
		PracticeDB.db_changed.emit()

func _on_new_pressed() -> void:
	$NameEdit.text = ""
	$ListOfWords.text = ""
	_fills_list.deselect_all()
	_editing_real_index = NONE
	_editing_original_name = ""
	$Save.text = "Add fill"
	$Save.disabled = true
	$Words.visible = false
	$Delete.visible = false

func _on_words_text_changed() -> void:
	$Save.disabled = false

func _on_words_pressed() -> void:
	print({"_editing_original_name":_editing_original_name})
	var fill_item: Dictionary = PracticeDB.fills[_editing_original_name]
	var kanji_words: Array = _list_get_kanji_words(fill_item.words)
	_create_words_if_missing(kanji_words)
	PracticeDB.filter_words = "|".join(kanji_words)
	print(kanji_words)
	jump_to_words.emit()
