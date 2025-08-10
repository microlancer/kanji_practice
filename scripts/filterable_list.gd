class_name FilterableList
extends Control

signal item_selected(index: int)
signal filter_changed(filter: String)

@onready var item_list: ItemList = $ScrollContainer/ItemList
@onready var filter_edit: TextEdit = $FilterEdit

@export var all_items: Array[String] = []
@export var all_items_metadata: Array[Dictionary] = []

var _visible_items_metadata: Array = []

func _ready() -> void:
	assert($ScrollContainer is Node)
	refresh_item_list()
	_visible_items_metadata = all_items_metadata
	#item_list = $ScrollContainer/ItemList

func _on_clear_button_pressed() -> void:
	filter_edit.text = ""
	refresh_item_list()
	filter_changed.emit(filter_edit.text)

func _on_filter_edit_text_changed() -> void:
	refresh_item_list()
	filter_changed.emit(filter_edit.text)

func refresh_item_list() -> void:
	item_list.clear()

	#print("Filter: " + filter_edit.text)

	print("Metadata count: " + str(all_items_metadata.size()))

	var index: int = 0
	if filter_edit.text == "":
		for i in all_items:
			item_list.add_item(i)
			if all_items_metadata.size() > 0:
				print("Setting metadata at " + str(index) + " to " + all_items_metadata[index].name)
				item_list.set_item_metadata(index, all_items_metadata[index])
			else:
				print("No metadata")
			index += 1
		_visible_items_metadata = all_items_metadata
		return

	# Filtered list
	var filter_or: PackedStringArray = filter_edit.text.split("|")
	index = 0
	var all_items_index = 0
	_visible_items_metadata = []
	for i in all_items:
		#print("Checking " + i + " for " + filter_edit.text)
		for j in filter_or:
			#print("Checking " + i + " for " + j)
			if i.contains(j):
				item_list.add_item(i)
				if all_items_metadata.size() > 0:
					print("Setting metadata")
					print("Setting metadata at " + str(index) + " to " + all_items_metadata[all_items_index].name)
					_visible_items_metadata.append(all_items_metadata[all_items_index])
					item_list.set_item_metadata(index, all_items_metadata[all_items_index])
					index += 1
				else:
					print("No metadata")
				#print("Setting metadata: " + i)
				#var data: Dictionary = {"name": i}
				break
		all_items_index += 1



func _on_item_list_item_selected(index: int) -> void:
	item_selected.emit(index)

func get_visible_items_metadata() -> Array:
	return _visible_items_metadata
