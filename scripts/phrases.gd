extends Control

@onready var phrase_list: FilterableList = $FilterableList

func _ready() -> void:

	for i in PracticeDB.phrases:
		phrase_list.all_items.append(i)

	phrase_list.refresh_item_list()

	return
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
