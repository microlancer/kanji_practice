extends Control

@onready var kanji_list: FilterableList = $FilterableList

func _ready() -> void:

	#kanji_list = $FilterableList/ScrollContainer/ItemList

	for i in PracticeDB.kanji:
		#var kanji = PracticeDB.kanji[i]
		kanji_list.all_items.append(i + " - needs drawing")

	kanji_list.refresh_item_list()
