extends CommonControl

signal jump_to_kanji

@onready var _words_list: FilterableList = $FilterableList


const NONE = -1

var _editing_real_index: int = NONE
var _editing_original_word: String = ""

func _ready() -> void:

	$MasteryLabel.text = ""
	_words_list.item_selected.connect(_on_item_selected)
	_words_list.filter_changed.connect(_on_filter_changed)

	init_from_db()
	_words_list.apply_filter()



func init_from_db() -> void:
	var all_words: Array[FilterableListItem] = []

	for word in PracticeDB.words:
		var word_item: WordItem = WordItem.new()
		word_item.word = word
		var db_word: Dictionary = PracticeDB.words[word]
		word_item.furigana = db_word.furigana

		if "due_read" not in PracticeDB.words[word]:
			PracticeDB.words[word]["mastery_read"] = 0
			PracticeDB.words[word]["mastery_write"] = 0
			PracticeDB.words[word]["due_read"] = 0
			PracticeDB.words[word]["due_write"] = 0

		word_item.mastery_read = int(db_word.mastery_read)
		word_item.mastery_write = int(db_word.mastery_write)
		word_item.due_read = int(db_word.due_read)
		word_item.due_write = int(db_word.due_write)
		word_item.fills = db_word.fills
		all_words.append(word_item)

	_words_list.init_all_items(all_words)
	init_filter()

func init_filter() -> void:
	_words_list.filter_edit.text = PracticeDB.filter_words
	_words_list.apply_filter()
	$Save.text = "Add word"
	$Save.disabled = true
	$Kanji.visible = false
	$Reset.visible = false
	$Delete.visible = false
	$WordEdit.text = ""
	$FuriganaEdit.text = ""
	$MasteryLabel.text = ""

	if _words_list.filter_edit.text != "":
		_words_list.select_by_visible_index(0)

func _on_item_selected(item: FilterableListItem) -> void:
	var word_item: WordItem = item as WordItem

	print({"selected": { "visible": word_item.visible_index, "real": word_item.real_index}})

	_editing_real_index = word_item.real_index
	_editing_original_word = word_item.word

	# it is possible that the DB was updated (by study) so use the latest
	var mastery_read = int(PracticeDB.words[word_item.word].mastery_read)
	var mastery_write = int(PracticeDB.words[word_item.word].mastery_write)

	var sec_read_remain: int = int(PracticeDB.words[word_item.word].due_read) -\
		int(Time.get_unix_time_from_system())
	var sec_write_remain: int = int(PracticeDB.words[word_item.word].due_write) -\
		int(Time.get_unix_time_from_system())

	var read_review_time_remaining: String = "review in " +\
		PracticeDB.sec_to_remain(sec_read_remain)
	var write_review_time_remaining: String = "review in " +\
		PracticeDB.sec_to_remain(sec_write_remain)

	if mastery_read == 0 or sec_read_remain <= 0:
		read_review_time_remaining = "due now"

	if mastery_write == 0 or sec_write_remain <= 0:
		write_review_time_remaining = "due now"

	$MasteryLabel.text = "Read: Level " + str(mastery_read) + " (" +\
		read_review_time_remaining + ")\n" +\
		"Write: Level " + str(mastery_write) + " (" +\
		write_review_time_remaining + ")"

	$WordEdit.text = word_item.word
	$FuriganaEdit.text = word_item.furigana
	$Delete.visible = true
	$Reset.visible = true
	$Kanji.visible = true
	$Kanji.disabled = false
	$Save.text = "Save"
	$Save.disabled = true

func _on_filter_changed(filter: String) -> void:

	PracticeDB.filter_fills = filter

	$WordEdit.text = ""
	$FuriganaEdit.text = ""
	$Delete.visible = false
	$Kanji.visible = false
	$Save.disabled = true
	_editing_real_index = NONE
	_editing_original_word = ""

func _on_save_pressed() -> void:
	var word = $WordEdit.text
	var furigana = $FuriganaEdit.text


	if word == "" or furigana == "":
		return


	var mastery_read = PracticeDB.words[word].mastery_read
	var mastery_write = PracticeDB.words[word].mastery_write

	if not JapaneseText.has_kanji(word):
		button_error($Save, "Kanji required in word")
		return

	if _editing_real_index == NONE:

		if word in PracticeDB.words:
			button_error($Save, "Word already exists")
			return

		_save_new_word(word, furigana, mastery_read, mastery_write)
	else:
		_update_existing_word(word, furigana, mastery_read, mastery_write)

	#var word_item: Dictionary = PracticeDB.words[word]

	$Kanji.disabled = false

	$Delete.visible = true
	print({"furigana":PracticeDB.words[word].furigana})

	$Kanji.visible = true

	# if the edited item is on the filtered list, try to select it
	_words_list.select_by_real_index(_editing_real_index)

	if _words_list.is_visible_by_real_index(_editing_real_index):
		_editing_original_word = word
	else:
		_editing_original_word = ""
		_editing_real_index = NONE

	$Save.disabled = true
	#restore_button(2, $Save, "Save")

	PracticeDB.db_changed.emit()

func _save_new_word(word: String, furigana: String, mastery_read: int, mastery_write: int) -> void:
	#$Save.text = "Added!"
	var new_word: WordItem = WordItem.new()
	new_word.word = word
	new_word.furigana = furigana
	_words_list.add_item(new_word)

	PracticeDB.words[word] = {
		"furigana": furigana,
		"mastery_read": mastery_read,
		"mastery_write": mastery_write,
		"fills": [] # TODO
	}

func _update_existing_word(word: String, furigana: String, mastery_read: int, mastery_write: int) -> void:
	#$Save.text = "Updated!"
	if word != _editing_original_word:
		# Word was changed, erase old word
		PracticeDB.words.erase(_editing_original_word)
		# Store into new name
		#_item_index_to_string[data.real_index] = item_name
		PracticeDB.words[word] = {
			"furigana": furigana,
			"mastery_read": mastery_read,
			"mastery_write": mastery_write,
			"fills": [] # TODO
		}
		#replace_list.all_items_metadata[data.real_index] = {"name": item_name, "real_index": data.real_index}

	PracticeDB.words[word].furigana = furigana
	PracticeDB.words[word].mastery_read = mastery_read
	PracticeDB.words[word].mastery_write = mastery_write
	PracticeDB.words[word].fills = [] # TODO
	var word_item: WordItem = _words_list.get_item_by_real_index(_editing_real_index)
	word_item.word = word
	word_item.furigana = furigana
	word_item.mastery_read = mastery_read
	word_item.mastery_write = mastery_write
	word_item.fills = [] # TODO
	_words_list.apply_filter()

func _on_text_changed() -> void:
	$Save.disabled = false

func _on_new_pressed() -> void:
	$WordEdit.text = ""
	$FuriganaEdit.text = ""
	_words_list.deselect_all()
	_editing_real_index = NONE
	_editing_original_word = ""
	$Save.text = "Add word"
	$Save.disabled = true
	$Kanji.visible = false
	$Delete.visible = false
	$MasteryLabel.text = ""
	$Reset.visible = false

func _on_kanji_pressed() -> void:
	print({"_editing_original_word":_editing_original_word})
	#var word_item: Dictionary = PracticeDB.words[_editing_original_word]
	var kanji_array: Array = PracticeDB.get_kanji_array(_editing_original_word)
	_create_kanji_if_missing(kanji_array)
	PracticeDB.filter_kanji = "|".join(kanji_array)
	#print(kanji_array)
	jump_to_kanji.emit()

#func _get_kanji_array(word: String) -> Array:
	#var kanji_array: Array = []
	#for c in word:
		#if JapaneseText.is_kanji(c):
			#kanji_array.append(c)
	#return kanji_array

func _create_kanji_if_missing(kanji_array: Array) -> void:
	print("Creating if missing")
	var added: bool = false
	for kanji in kanji_array:
		if not PracticeDB.kanji.has(kanji):
			print("Adding to kanji: " + kanji)
			PracticeDB.kanji[kanji] = {
				"draw_data": [],
				"words": [], #TODO
			}
			added = true
		else:
			print("Already exists: " + kanji)

	if added:
		PracticeDB.db_changed.emit()
