extends Control

@onready var words_list: FilterableList = $FilterableList

var _item_index_to_string: Array = []

func _ready() -> void:

	for i in PracticeDB.words:
		var word = PracticeDB.words[i]
		words_list.all_items.append(i + " (" + word.furigana + ")")

	words_list.refresh_item_list()

func refresh() -> void:

	#replace_list.item_list.clear()

	words_list.all_items = []
	_item_index_to_string = []

	#var index = 0
	for i in PracticeDB.words:
		var word_item: Dictionary = PracticeDB.words[i]
		print(i)
		print(word_item.furigana)
		words_list.all_items.append(i + "(" + word_item.furigana + ")")
		_item_index_to_string.append(i)
		#index += 1

	words_list.filter_edit.text = PracticeDB.filter_lists

	words_list.refresh_item_list()
