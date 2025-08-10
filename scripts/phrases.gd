extends Control

@onready var phrase_list: ItemList = $ScrollContainer/ItemList

func _ready() -> void:
	phrase_list.add_item("駅{えき}の前{まえ}で待{ま}っています")
	phrase_list.add_item("<place>で<doing>")
	phrase_list.add_item("hello")
	phrase_list.add_item("hello")
	phrase_list.add_item("hello")
	phrase_list.add_item("hello")
	phrase_list.add_item("hello")
	phrase_list.add_item("hello")
	phrase_list.add_item("hello")
	phrase_list.add_item("hello")
	phrase_list.add_item("hello")
	phrase_list.add_item("hello")
