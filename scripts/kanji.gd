extends Control

@onready var _kanji_list: FilterableList = $FilterableList

func _ready() -> void:

	init_from_db()

func init_from_db() -> void:
	var all_kanji: Array[FilterableListItem] = []

	for i in PracticeDB.words:
		var kanji: KanjiItem = KanjiItem.new()
		all_kanji.append(kanji)

	_kanji_list.init_all_items(all_kanji)
	_kanji_list.filter_edit.text = PracticeDB.filter_kanji
	_kanji_list.apply_filter()
