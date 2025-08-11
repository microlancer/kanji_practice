class_name FilterableList
extends Control

signal item_selected(item: FilterableListItem)
signal filter_changed(filter: String)

const ITEM_NOT_VISIBLE = -1

#@onready var item_list: ItemList = $ScrollContainer/ItemList
@onready var filter_edit: TextEdit = $FilterEdit

#@export var all_items: Array[String] = []
#@export var all_items_metadata: Array[Dictionary] = []

@onready var _item_list: ItemList = $ScrollContainer/ItemList
#var _visible_items_metadata: Array = []

var _all_items: Array[FilterableListItem] = []

func _ready() -> void:
	assert($ScrollContainer is Node)
	apply_filter()
	#_visible_items_metadata = all_items_metadata
	#item_list = $ScrollContainer/ItemList

func _on_clear_button_pressed() -> void:
	filter_edit.text = ""
	apply_filter()
	filter_changed.emit(filter_edit.text)

func _on_filter_edit_text_changed() -> void:
	apply_filter()
	filter_changed.emit(filter_edit.text)

func apply_filter() -> void:
	_item_list.clear()
	_item_list.remove_theme_color_override("font_hovered_selected_color")
	_item_list.remove_theme_color_override("font_selected_color")
	#_item_list.remove_theme_color_override("font_hovered_color")

	#print("Filter: " + filter_edit.text)

	#print("Metadata count: " + str(all_items_metadata.size()))

	var visible_index: int = 0
	var real_index: int = 0
	if filter_edit.text == "":
		for item in _all_items:
			_item_list.add_item(item.get_text())
			if not item.is_valid():
				_item_list.set_item_custom_fg_color(visible_index, Color.RED)
			_item_list.set_item_metadata(visible_index, {
				"visible_index": visible_index,
				"real_index": real_index
			})
			item.visible_index = visible_index
			print("Set visible index to: " + str(visible_index))
			item.real_index = real_index
			#if all_items_metadata.size() > 0:
			#	print("Setting metadata at " + str(index) + " to " + all_items_metadata[index].name)
			#	item_list.set_item_metadata(index, all_items_metadata[index])
			#else:
			#	print("No metadata")
			visible_index += 1
			real_index += 1
		#_visible_items_metadata = all_items_metadata
		return

	# Filtered list
	var filter_or: PackedStringArray = filter_edit.text.split("|")
	visible_index = 0
	real_index = 0
	#_visible_items_metadata = []
	for item in _all_items:
		#print("Checking " + i + " for " + filter_edit.text)
		for j in filter_or:
			#print("Checking " + i + " for " + j)
			if item.get_text().contains(j):
				_item_list.add_item(item.get_text())
				_item_list.set_item_metadata(visible_index, {
					"visible_index": visible_index,
					"real_index": real_index
				})
				item.visible_index = visible_index
				item.real_index = real_index
				if not item.is_valid():
					_item_list.set_item_custom_fg_color(visible_index, Color.RED)
				#if all_items_metadata.size() > 0:
				#	print("Setting metadata")
				#	print("Setting metadata at " + str(index) + " to " + all_items_metadata[all_items_index].name)
				#	_visible_items_metadata.append(all_items_metadata[all_items_index])
				#	item_list.set_item_metadata(index, all_items_metadata[all_items_index])
				visible_index += 1
				#else:
				#	print("No metadata")
				#print("Setting metadata: " + i)
				#var data: Dictionary = {"name": i}
				break
			else:
				# Did not match filter, so there is no visible index.
				item.visible_index = ITEM_NOT_VISIBLE
				item.real_index = real_index

		real_index += 1

#func set_item_by_real_index(real_index: int, item: FilterableListItem) -> void:
#	pass

#func set_item_by_visible_index(visible_index: int, item: FilterableListItem) -> void:
#	pass

func init_all_items(items: Array[FilterableListItem]) -> void:
	_all_items = items
	var real_index = 0
	for item in _all_items:
		item.real_index = real_index
		item.visible_index = real_index # all visible on init
		real_index += 1

func add_item(item: FilterableListItem) -> void:
	var real_index = _all_items.size()
	item.real_index = real_index
	_all_items.append(item)
	apply_filter()

func _on_item_list_item_selected(visible_index: int) -> void:
	var data = _item_list.get_item_metadata(visible_index)
	var real_index = data.real_index
	var item = _all_items[real_index]

	if not item.is_valid():
		_item_list.add_theme_color_override("font_hovered_selected_color", Color.LIGHT_SALMON)
		_item_list.add_theme_color_override("font_selected_color", Color.LIGHT_SALMON)
		#_item_list.add_theme_color_override("font_hovered_color", Color.LIGHT_PINK)
	else:
		_item_list.remove_theme_color_override("font_hovered_selected_color")
		_item_list.remove_theme_color_override("font_selected_color")
		#_item_list.remove_theme_color_override("font_hovered_color")

	item_selected.emit(item)

#func get_visible_items_metadata() -> Array:
#	return _visible_items_metadata


func select_by_real_index(real_index: int) -> void:
	# We convert real index to visible index (if possible)
	_item_list.select(_all_items[real_index].visible_index)
	_item_list.ensure_current_is_visible()

	#var visible_items_data: Array = replace_list.get_visible_items_metadata()
	#var index = 0
	#for data in visible_items_data:
		#var data: Dictionary = visible_items_data[i]
		#if data.name == item_name:
		#	replace_list.item_list.select(index)
		#index += 1

func is_visible_by_real_index(real_index: int) -> bool:
	return _all_items[real_index].visible_index != ITEM_NOT_VISIBLE

func deselect_all() -> void:
	_item_list.deselect_all()

func get_item_by_real_index(real_index: int) -> FilterableListItem:
	return _all_items[real_index]
