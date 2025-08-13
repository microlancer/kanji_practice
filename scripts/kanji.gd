extends Control

@onready var _kanji_list: FilterableList = $FilterableList
var _editing_real_index: int = 0
var _strokes: Array = []

const NONE = -1
@onready var _draw_panel: DrawPanel = $DrawPanel

func _ready() -> void:

	_kanji_list.item_selected.connect(_on_item_selected)
	_kanji_list.filter_changed.connect(_on_filter_changed)
	init_from_db()

	#_draw_panel.stroke_drawn.connect(_on_stroke_drawn)
	#draw_panel.connect("stroke_drawn", Callable(self, "_on_stroke_drawn"))
	$Example.visible = false
	$Redraw.disabled = true
	_draw_panel.disable()

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
	$Example.visible = false
	$Example.modulate = Color(255, 255, 255, 1)
	$KanjiEdit.text = ""
	_draw_panel.disable()

	if _kanji_list.filter_edit.text != "":
		_kanji_list.select_by_visible_index(0)

func _on_filter_changed(filter: String) -> void:
	if filter == "":
		$Example.visible = false
		$Example.modulate = Color(255, 255, 255, 1)
		$KanjiEdit.text = ""

func _on_item_selected(item: FilterableListItem) -> void:
	var kanji_item: KanjiItem = item as KanjiItem
	_editing_real_index = kanji_item.real_index
	$KanjiEdit.text = kanji_item.text
	$Redraw.disabled = false

	if kanji_item.draw_data.is_empty():
		$Example.visible = true
		$Example.text = kanji_item.text
		$Example.modulate = Color(255, 255, 255, 0.2)
	else:
		$Example.text = kanji_item.text
		$Example.visible = true
		$Example.modulate = Color(255, 255, 255, 1)


func _on_redraw_pressed() -> void:

	if $Redraw.text == "Save":
		# Store the collected stroke data
		_draw_panel.disable()
		var kanji = $KanjiEdit.text
		var kanji_item: KanjiItem = _kanji_list.get_item_by_real_index(_editing_real_index)
		kanji_item.draw_data = _strokes
		PracticeDB.kanji[kanji].draw_data = kanji_item.draw_data
		_kanji_list.apply_filter()
		PracticeDB.db_changed.emit()

		# if the edited item is on the filtered list, try to select it
		_kanji_list.select_by_real_index(_editing_real_index)

		$Redraw.text = "Redraw"

		if _kanji_list.is_visible_by_real_index(_editing_real_index):
			$Redraw.disabled = false
			_draw_panel.enable()
			_draw_panel.clear()
		else:
			$Redraw.disabled = true
			_draw_panel.disable()
			_editing_real_index = NONE

		$Example.text = kanji
		$Example.visible = true
		$Example.modulate = Color(255, 255, 255, 1)

	else:
		# Start collecting stroke data
		_draw_panel.enable()
		_strokes = []
		$Redraw.text = "Save"
		$Example.text = $KanjiEdit.text
		$Example.modulate = Color(255, 255, 255, 0.2)
		$Example.visible = true



func _on_draw_panel_stroke_drawn(strokeIndex: int, direction: String) -> void:
	print({"n":strokeIndex,"d":direction})
	_strokes.append(direction)
