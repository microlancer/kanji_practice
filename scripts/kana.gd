extends Control

@onready var _kana_list: FilterableList = $FilterableList
var _editing_real_index: int = 0
var _strokes: Array = []

const NONE = -1
@onready var _draw_panel: DrawPanel = $DrawPanel

func _ready() -> void:

	_kana_list.item_selected.connect(_on_item_selected)
	_kana_list.filter_changed.connect(_on_filter_changed)
	init_from_db()

	#_draw_panel.stroke_drawn.connect(_on_stroke_drawn)
	#draw_panel.connect("stroke_drawn", Callable(self, "_on_stroke_drawn"))
	$Example.visible = false
	$Redraw.disabled = true
	_draw_panel.disable()

func init_from_db() -> void:
	var all_kana: Array[FilterableListItem] = []

	for kana in PracticeDB.kana:
		#print(kana)
		var kana_item: KanaItem = KanaItem.new()
		kana_item.text = kana
		if "draw_data" not in PracticeDB.kana[kana]:
			PracticeDB.kana[kana] = {
				"draw_data": ""
			}
		kana_item.draw_data = PracticeDB.kana[kana].draw_data
		all_kana.append(kana_item)

	#print(all_kana)

	_kana_list.init_all_items(all_kana)
	init_filter()

func init_filter() -> void:
	_kana_list.filter_edit.text = PracticeDB.filter_kana
	_kana_list.apply_filter()
	$Example.visible = false
	$Example.modulate = Color(255, 255, 255, 1)
	$KanaEdit.text = ""
	_draw_panel.disable()

	if _kana_list.filter_edit.text != "":
		_kana_list.select_by_visible_index(0)

func _on_filter_changed(filter: String) -> void:
	if filter == "":
		$Example.visible = false
		$Example.modulate = Color(255, 255, 255, 1)
		$KanaEdit.text = ""

func _on_item_selected(item: FilterableListItem) -> void:
	var kana_item: KanaItem = item as KanaItem
	_editing_real_index = kana_item.real_index
	$KanaEdit.text = kana_item.text
	$Redraw.disabled = false

	if kana_item.draw_data.is_empty():
		$Example.visible = true
		$Example.text = kana_item.text
		$Example.modulate = Color(255, 255, 255, 0.2)
	else:
		$Example.text = kana_item.text
		$Example.visible = true
		$Example.modulate = Color(255, 255, 255, 1)


func _on_redraw_pressed() -> void:

	if $Redraw.text == "Save":
		# Store the collected stroke data
		_draw_panel.disable()
		var kana: String = $KanaEdit.text
		var kana_item: KanaItem = _kana_list.get_item_by_real_index(_editing_real_index)
		assert(_strokes.size() > 0)
		print("before", _strokes.size())
		var base64_draw_data = PracticeDB.encode_all_strokes(_strokes)

		var check: Array = PracticeDB.decode_all_strokes(base64_draw_data)
		assert(check.size() == _strokes.size())
		print("after", check.size())

		kana_item.draw_data = base64_draw_data
		#print(PracticeDB.kana[kana])
		#print(typeof(PracticeDB.kana[kana]), PracticeDB.kana[kana])
		if "draw_data" not in PracticeDB.kana[kana]:
			PracticeDB.kana[kana] = {
				"draw_data": ""
			}
		PracticeDB.kana[kana].draw_data = kana_item.draw_data
		_kana_list.apply_filter()
		PracticeDB.mark_valid_items()
		PracticeDB.db_changed.emit()

		# if the edited item is on the filtered list, try to select it
		_kana_list.select_by_real_index(_editing_real_index)

		$Redraw.text = "Clear and redraw"

		if _kana_list.is_visible_by_real_index(_editing_real_index):
			$Redraw.disabled = false
			_draw_panel.enable()
			_draw_panel.clear()
		else:
			$Redraw.disabled = true
			_draw_panel.disable()
			_editing_real_index = NONE

		$Example.text = kana
		$Example.visible = true
		$Example.modulate = Color(255, 255, 255, 1)

	else:
		# Start collecting stroke data
		_draw_panel.enable()
		_strokes = []
		$Redraw.text = "Save"
		$Example.text = $KanaEdit.text
		$Example.modulate = Color(255, 255, 255, 0.2)
		$Example.visible = true




func _on_draw_panel_stroke_drawn_raw(strokeIndex: int, points: Array) -> void:
	#print({"points":points})
	print({"strokeIndex":strokeIndex})
	# Convert raw points to signature
	var sig = StrokeUtils.process_stroke(points, 32, 0.02, true)
	print("Appending stroke")
	_strokes.append(sig)

	pass # Replace with function body.
