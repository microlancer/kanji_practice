class_name FilterableList
extends Control

signal item_selected(index: int)

@onready var item_list: ItemList = $ScrollContainer/ItemList
@onready var filter_edit: TextEdit = $FilterEdit

@export var all_items: Array[String] = []

func _ready() -> void:
	assert($ScrollContainer is Node)
	refresh_item_list()
	#item_list = $ScrollContainer/ItemList

func _on_clear_button_pressed() -> void:
	filter_edit.text = ""
	refresh_item_list()

func _on_filter_edit_text_changed() -> void:
	refresh_item_list()

func refresh_item_list() -> void:
	item_list.clear()

	#print("Filter: " + filter_edit.text)


	if filter_edit.text == "":
		for i in all_items:
			item_list.add_item(i)
		return

	# Filtered list
	var filter_or: PackedStringArray = filter_edit.text.split("|")
	for i in all_items:
		#print("Checking " + i + " for " + filter_edit.text)
		for j in filter_or:
			#print("Checking " + i + " for " + j)
			if i.contains(j):
				item_list.add_item(i)
				break


func _on_item_list_item_selected(index: int) -> void:
	item_selected.emit(index)
