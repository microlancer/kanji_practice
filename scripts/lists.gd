extends Control

@onready var replace_list: ItemList = $ScrollContainer/ItemList

func _ready() -> void:

	replace_list.add_item("place: 家,会社,公園,自宅")
	replace_list.add_item("person: 田中さん,マイケルくん")
	replace_list.add_item("edible: チキン,ラーメン,お寿司")
	replace_list.add_item("food_adj: おいしいな,辛いな,冷たいな,熱いな")
	replace_list.add_item("<place>")
	replace_list.add_item("<place>")
	replace_list.add_item("<place>")
	replace_list.add_item("<place>")
	replace_list.add_item("<place>")
	replace_list.add_item("<place>")
