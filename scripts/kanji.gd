extends Control

@onready var _kanji_list: FilterableList = $FilterableList
var _editing_real_index: int = 0

func _ready() -> void:

	_kanji_list.item_selected.connect(_on_item_selected)
	init_from_db()

	$Redraw.disabled = true

func init_from_db() -> void:
	var all_kanji: Array[FilterableListItem] = []

	for kanji in PracticeDB.kanji:
		print(kanji)
		var kanji_item: KanjiItem = KanjiItem.new()
		kanji_item.text = kanji
		kanji_item.draw_data = PracticeDB.kanji[kanji].draw_data
		all_kanji.append(kanji_item)

	print(all_kanji)

	_kanji_list.init_all_items(all_kanji)
	init_filter()

func init_filter() -> void:
	_kanji_list.filter_edit.text = PracticeDB.filter_kanji
	_kanji_list.apply_filter()

func _on_item_selected(item: FilterableListItem) -> void:
	var kanji_item: KanjiItem = item as KanjiItem
	_editing_real_index = kanji_item.real_index
	$KanjiEdit.text = kanji_item.text
	$Redraw.disabled = false


func _on_redraw_pressed() -> void:
	var kanji = $KanjiEdit.text
	var kanji_item: KanjiItem = _kanji_list.get_item_by_real_index(_editing_real_index)
	kanji_item.draw_data = ["L","R"]
	PracticeDB.kanji[kanji].draw_data = kanji_item.draw_data
	_kanji_list.apply_filter()
	PracticeDB.db_changed.emit()
