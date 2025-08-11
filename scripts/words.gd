extends Control

@onready var _words_list: FilterableList = $FilterableList

#var _item_index_to_string: Array = []

func _ready() -> void:

	init_from_db()


	_words_list.apply_filter()

func init_from_db() -> void:
	var all_words: Array[FilterableListItem] = []

	for word in PracticeDB.words:
		var word_item: WordItem = WordItem.new()
		word_item.word = word
		word_item.furigana = PracticeDB.words[word].furigana
		word_item.mastery = PracticeDB.words[word].mastery
		word_item.fills = PracticeDB.words[word].fills
		all_words.append(word_item)

	_words_list.init_all_items(all_words)
	_words_list.filter_edit.text = PracticeDB.filter_words
	_words_list.apply_filter()
#
#func refresh() -> void:
#
	##replace_list.item_list.clear()
#
	#words_list.all_items = []
	#_item_index_to_string = []
#
	##var index = 0
	#for i in PracticeDB.words:
		#var word_item: Dictionary = PracticeDB.words[i]
		#print(i)
		#print(word_item.furigana)
		#words_list.all_items.append(i + "(" + word_item.furigana + ")")
		#_item_index_to_string.append(i)
		##index += 1
#
	#words_list.filter_edit.text = PracticeDB.filter_lists
#
	#words_list.refresh_item_list()
