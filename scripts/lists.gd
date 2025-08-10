extends Control

@onready var replace_list: FilterableList = $FilterableList

func _ready() -> void:
	refresh()

	#for i in PracticeDB.lists:
		#var list = PracticeDB.lists[i]
		#replace_list.all_items.append(i + ": " + ",".join(list.words))
#
	#replace_list.refresh_item_list()

	#return
	#replace_list.add_item("place: 家,会社,公園,自宅")
	#replace_list.add_item("person: 田中さん,マイケルくん")
	#replace_list.add_item("edible: チキン,ラーメン,お寿司")
	#replace_list.add_item("food_adj: おいしいな,辛いな,冷たいな,熱いな")
	#replace_list.add_item("<place>")
	#replace_list.add_item("<place>")
	#replace_list.add_item("<place>")
	#replace_list.add_item("<place>")
	#replace_list.add_item("<place>")
	#replace_list.add_item("<place>")

func refresh() -> void:

	#replace_list.item_list.clear()

	replace_list.all_items = []

	for i in PracticeDB.lists:
		var list = PracticeDB.lists[i]
		replace_list.all_items.append(i + ": " + ",".join(list.words))

	replace_list.filter_edit.text = PracticeDB.filter_lists

	replace_list.refresh_item_list()

	#apply_filter()
#
#func apply_filter() -> void:
	#replace_list.filter_edit.text = PracticeDB.filter_lists
	#replace_list.refresh_item_list()
