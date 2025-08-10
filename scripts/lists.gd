extends Common

const NONE = -1

signal jump_to_words

@onready var replace_list: FilterableList = $FilterableList

var _item_index_to_string: Array = []

var _editing_index = NONE

func _ready() -> void:

	replace_list.item_selected.connect(_on_item_selected)
	replace_list.filter_changed.connect(_on_filter_changed)
	refresh()


	$Save.disabled = true
	$Delete.visible = false
	$Words.visible = false

func refresh() -> void:

	#replace_list.item_list.clear()

	replace_list.all_items = []
	replace_list.all_items_metadata = []
	_item_index_to_string = []

	#var list1: ItemList = ItemList.new()
	#list1.add_item("apple")
	#list1.set_item_metadata(0, {"type": "fruit"})
	#var data1: Dictionary = list1.get_item_metadata(0)
	#print(data1.type)

	var index = 0
	for i in PracticeDB.lists:
		var list = PracticeDB.lists[i]
		replace_list.all_items.append(i + ": " + ",".join(list.words))
		print("Adding metadata: " + i)
		#var data: Dictionary = {"food":"food"}
		replace_list.all_items_metadata.append({"name":i, "real_index": index})
		print({"meta":replace_list.all_items_metadata})
		print("All metadata: " + str(replace_list.all_items_metadata.size()))
		_item_index_to_string.append(i)
		index += 1

	replace_list.filter_edit.text = PracticeDB.filter_lists

	print("All metadata: " + str(replace_list.all_items_metadata.size()))

	replace_list.refresh_item_list()

	#_update_item_metadata()
	# Update metadata

#func _update_item_metadata() -> void:
	#var total_items: int = replace_list.item_list.item_count
	#for index in range(0, total_items):
		#print("Count: " + str(replace_list.item_list.item_count))
		#var item_name = _item_index_to_string[index]
		#replace_list.all_items_metadata.append({"name": item_name})

func _on_item_selected(index: int) -> void:
	print("Picked " + str(index))

	var data: Dictionary = replace_list.item_list.get_item_metadata(index)

	var list_name: String = data.name
	print(list_name)
	var list_item: Dictionary = PracticeDB.lists[list_name]
	print(list_item)
	_editing_index = index
	$NameEdit.text = list_name
	$ListOfWords.text = ",".join(list_item.words)
	$Delete.visible = true
	$Words.visible = true

	if _list_contains_kanji_words(list_item.words):
		$Words.disabled = false
	else:
		$Words.disabled = true

	$Save.text = "Save"
	$Save.disabled = true

func _on_filter_changed(filter: String) -> void:
	_item_index_to_string = []
	#var index = 0
	var total_items = replace_list.item_list.item_count
	print("Total items: " + str(total_items))
	for i in range(0, total_items):
		print(replace_list.item_list.get_item_text(i))
		print(replace_list.all_items_metadata)
		var data: Dictionary = replace_list.item_list.get_item_metadata(i)
		print(data)
		var item_name: String = replace_list.item_list.get_item_metadata(i).name
		_item_index_to_string.append(item_name)

	PracticeDB.filter_lists = filter

	$ListOfWords.text = ""
	$NameEdit.text = ""
	$Delete.visible = false
	$Words.visible = false
	$Save.disabled = true
	_editing_index = NONE

func _list_contains_kanji_words(words: Array) -> bool:
	for i in words:
		if JapaneseText.is_kanji(i):
			return true
	return false

func _list_get_kanji_words(words: Array) -> Array:
	var kanji_words: Array = []
	for i in words:
		if JapaneseText.is_kanji(i):
			kanji_words.append(i)
	return kanji_words

func _on_save_pressed() -> void:

	var item_name = $NameEdit.text
	var words = $ListOfWords.text
	#var visible_index: int = 0

	if words == "" or item_name == "":
		return

	#if PracticeDB.lists.has(item_name):
		#$Save.text = "Already exists"
		#PracticeDB.set_button_color($Save, Color.RED)
		#_restore_button(2, $Save, "Save")
		#return


	if _editing_index == NONE:
		$Save.text = "Added!"
		replace_list.all_items.append(item_name)
		#visible_index = replace_list.item_list.item_count - 1

		PracticeDB.lists[item_name] = {
			"words": $ListOfWords.text.split(","),
			"phrases": [] # TODO
		}
		print(replace_list.all_items)
		#_editing_index = replace_list.all_items.size() - 1
		var real_index = replace_list.all_items.size() - 1
		replace_list.all_items_metadata.append({"name": item_name, "real_index": real_index})
		_item_index_to_string.append(item_name)
	else:

		var data: Dictionary = replace_list.item_list.get_item_metadata(_editing_index)

		#var item_index = data.real_index

		replace_list.all_items[data.real_index] = item_name
		print({"items":_item_index_to_string})
		if item_name != _item_index_to_string[data.real_index]:
			# Name was changed, erase old name
			PracticeDB.lists.erase(_item_index_to_string[data.real_index])
			# Store into new name
			_item_index_to_string[data.real_index] = item_name
			PracticeDB.lists[item_name] = {"words":[],"phrases":[]}
			replace_list.all_items_metadata[data.real_index] = {"name": item_name, "real_index": data.real_index}

		PracticeDB.lists[item_name].words = $ListOfWords.text.split(",")
		PracticeDB.lists[item_name].phrases = [] # TODO
		$Save.text = "Updated!"

	var list_item: Dictionary = PracticeDB.lists[item_name]


	if _list_contains_kanji_words(list_item.words):
		$Words.disabled = false
	else:
		$Words.disabled = true

	$Delete.visible = true
	print({"words":PracticeDB.lists[item_name].words})

	if not PracticeDB.lists[item_name].words.is_empty():
		$Words.visible = true
	else:
		print("No words")
		$Words.visible = false


	refresh()

	# if the edited item is on the filtered list, try to select it
	var visible_items_data: Array = replace_list.get_visible_items_metadata()
	var index = 0
	for data in visible_items_data:
		#var data: Dictionary = visible_items_data[i]
		if data.name == item_name:
			replace_list.item_list.select(index)
		index += 1

	$Save.disabled = true
	_restore_button(2, $Save, "Save")

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
	replace_list.item_list.deselect_all()
	_editing_index = NONE
	$Save.text = "Add list"
	$Save.disabled = true
	$Words.visible = false
	$Delete.visible = false


func _on_words_text_changed() -> void:
	$Save.disabled = false

func _on_words_pressed() -> void:
	var item_name: String = _item_index_to_string[_editing_index]
	var item: Dictionary = PracticeDB.lists[item_name]
	#replace_list.all_items[_editing_index]
	var kanji_words: Array = _list_get_kanji_words(item.words)
	_create_words_if_missing(kanji_words)
	PracticeDB.filter_lists = "|".join(kanji_words)
	print(kanji_words)

	jump_to_words.emit()
