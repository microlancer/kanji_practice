extends Control

@onready var words_list: FilterableList = $FilterableList

func _ready() -> void:

	for i in PracticeDB.words:
		var word = PracticeDB.words[i]
		words_list.all_items.append(i + " (" + word.furigana + ")")

	words_list.refresh_item_list()
