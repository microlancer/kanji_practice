extends Control

const FILLS_TAB_INDEX = 2
const WORDS_TAB_INDEX = 3

func _ready() -> void:
	$TabBar/Phrases.jump_to_fills.connect(_on_jump_to_fills)
	$TabBar/Fills.jump_to_words.connect(_on_jump_to_words)

func _on_tab_bar_tab_changed(tab: int) -> void:
	for i in $TabBar.get_children():
		if i.get_index() != tab:
			i.visible = false
		else:
			i.visible = true

func _on_jump_to_fills() -> void:
	$TabBar.current_tab = FILLS_TAB_INDEX
	$TabBar/Fills.init_from_db() # new empty fills possibly added

func _on_jump_to_words() -> void:
	$TabBar.current_tab = WORDS_TAB_INDEX
	$TabBar/Words.init_from_db() # new empty words possibly added
