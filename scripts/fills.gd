extends Common

const NONE = -1

signal jump_to_words

@onready var _fills_list: FilterableList = $FilterableList

#var _item_index_to_string: Array = []

#var _editing_index: int = NONE
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

	#replace_list.item_list.clear()

	#fills_list.all_items = []
	#fills_list.all_items_metadata = []
	#_item_index_to_string = []

	#var list1: ItemList = ItemList.new()
	#list1.add_item("apple")
	#list1.set_item_metadata(0, {"type": "fruit"})
	#var data1: Dictionary = list1.get_item_metadata(0)
	#print(data1.type)

	var all_items: Array[FilterableListItem] = []

	#var real_index = 0
	for fill_name in PracticeDB.fills:
		var fill: FillItem = FillItem.new()
		print(PracticeDB.fills[fill_name])
		fill.name = fill_name
		fill.words = PracticeDB.fills[fill_name].words
		fill.phrases = PracticeDB.fills[fill_name].phrases
		all_items.append(fill)
		#_item_index_to_string.append(i)
		#real_index += 1

	_fills_list.init_all_items(all_items)
	init_filter()

	#_update_item_metadata()
	# Update metadata

func init_filter() -> void:
	_fills_list.filter_edit.text = PracticeDB.filter_fills
	_fills_list.apply_filter()

#func _update_item_metadata() -> void:
	#var total_items: int = replace_list.item_list.item_count
	#for index in range(0, total_items):
		#print("Count: " + str(replace_list.item_list.item_count))
		#var item_name = _item_index_to_string[index]
		#replace_list.all_items_metadata.append({"name": item_name})

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

	$Save.text = "Save"
	$Save.disabled = true

func _on_filter_changed(filter: String) -> void:
	#_item_index_to_string = []
	#var index = 0
	#var total_items = replace_list.item_list.item_count
	#print("Total items: " + str(total_items))
	#for i in range(0, total_items):
		#print(replace_list.item_list.get_item_text(i))
		#print(replace_list.all_items_metadata)
		#var data: Dictionary = replace_list.item_list.get_item_metadata(i)
		#print(data)
		#var item_name: String = replace_list.item_list.get_item_metadata(i).name
		#_item_index_to_string.append(item_name)

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
	#var visible_index: int = 0

	if words == "" or fill_name == "":
		return

	#if PracticeDB.lists.has(item_name):
		#$Save.text = "Already exists"
		#PracticeDB.set_button_color($Save, Color.RED)
		#_restore_button(2, $Save, "Save")
		#return


	if _editing_real_index == NONE:
		_save_new_fill(fill_name, words_array)
		#print(replace_list.all_items)
		#_editing_index = replace_list.all_items.size() - 1
		#var real_index = replace_list.all_items.size() - 1
		#replace_list.all_items_metadata.append({"name": item_name, "real_index": real_index})
		#_item_index_to_string.append(item_name)
	else:
		_update_existing_fill(fill_name, words_array)
		#fills_list.set_item_by_real_index(_editing_real_index,


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


	#fills_list.apply_filter()

	# if the edited item is on the filtered list, try to select it

	_fills_list.select_by_real_index(_editing_real_index)

	if _fills_list.is_visible_by_real_index(_editing_real_index):
		_editing_original_name = fill_name
	else:
		_editing_original_name = ""
		_editing_real_index = NONE

	$Save.disabled = true
	_restore_button(2, $Save, "Save")

func _save_new_fill(fill_name: String, words_array: Array) -> void:
	$Save.text = "Added!"
	var new_item: FillItem = FillItem.new()
	new_item.name = fill_name
	new_item.words = words_array
	_fills_list.add_item(new_item)
	#replace_list.all_items.append(item_name)
	#visible_index = replace_list.item_list.item_count - 1

	PracticeDB.lists[new_item.name] = {
		"words": new_item.words,
		"phrases": [] # TODO
	}

func _update_existing_fill(fill_name: String, words_array: Array) -> void:
	$Save.text = "Updated!"
	if fill_name != _editing_original_name:
		# Name was changed, erase old name
		PracticeDB.fills.erase(_editing_original_name)
		# Store into new name
		#_item_index_to_string[data.real_index] = item_name
		PracticeDB.fills[fill_name] = {
			"words": [],
			"phrases": []
		}
		#replace_list.all_items_metadata[data.real_index] = {"name": item_name, "real_index": data.real_index}

	PracticeDB.fills[fill_name].words = words_array
	PracticeDB.fills[fill_name].phrases = [] # TODO
	var fill: FillItem = _fills_list.get_item_by_real_index(_editing_real_index)
	fill.name = fill_name
	fill.words = words_array
	fill.phrases = [] # TODO
	_fills_list.apply_filter()
	#apply_filter()
#
#func apply_filter() -> void:
	#replace_list.filter_edit.text = PracticeDB.filter_lists
	#replace_list.refresh_item_list()

func _create_words_if_missing(words: Array) -> void:
	print("Creating if missing")
	for i in words:
		if not PracticeDB.words.has(i):
			print("Adding to words: " + i)
			PracticeDB.words[i] = {
				"furigana": "",
				"mastery": 0,
				"lists": [], #TODO
			}
		else:
			print("Already exists: " + i)

func _on_new_pressed() -> void:
	$NameEdit.text = ""
	$ListOfWords.text = ""
	_fills_list.deselect_all()
	#_editing_index = NONE
	_editing_real_index = NONE
	_editing_original_name = ""
	$Save.text = "Add list"
	$Save.disabled = true
	$Words.visible = false
	$Delete.visible = false


func _on_words_text_changed() -> void:
	$Save.disabled = false

func _on_words_pressed() -> void:
	#var item_name: String = _item_index_to_string[_editing_index]
	print({"_editing_original_name":_editing_original_name})
	var fill_item: Dictionary = PracticeDB.fills[_editing_original_name]
	#replace_list.all_items[_editing_index]
	var kanji_words: Array = _list_get_kanji_words(fill_item.words)
	_create_words_if_missing(kanji_words)
	PracticeDB.filter_words = "|".join(kanji_words)
	print(kanji_words)

	jump_to_words.emit()
