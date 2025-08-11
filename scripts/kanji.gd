extends Control

@onready var _kanji_list: FilterableList = $FilterableList
var _editing_real_index: int = 0

func _ready() -> void:

	_kanji_list.item_selected.connect(_on_item_selected)
	init_from_db()

func init_from_db() -> void:
	var all_kanji: Array[FilterableListItem] = []

	for kanji in PracticeDB.kanji:
		print(kanji)
		var kanji_item: KanjiItem = KanjiItem.new()
		kanji_item.text = kanji
		all_kanji.append(kanji_item)

	print(all_kanji)

	_kanji_list.init_all_items(all_kanji)
	_kanji_list.filter_edit.text = PracticeDB.filter_kanji
	_kanji_list.apply_filter()

func _on_item_selected(item: FilterableListItem) -> void:
	var kanji_item: KanjiItem = item as KanjiItem
	_editing_real_index = kanji_item.real_index
	$KanjiEdit.text = kanji_item.text
