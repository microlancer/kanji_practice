extends Control

const FILLS_TAB_INDEX = 2
const WORDS_TAB_INDEX = 3
const KANJI_TAB_INDEX = 4

func _ready() -> void:
	$TabBar/Phrases.jump_to_fills.connect(_on_jump_to_fills)
	$TabBar/Fills.jump_to_words.connect(_on_jump_to_words)
	$TabBar/Words.jump_to_kanji.connect(_on_jump_to_kanji)

	PracticeDB.db_changed.connect(_on_db_changed)
	PracticeDB.db_loaded.connect(_on_db_loaded)

func _on_db_loaded() -> void:
	$TabBar/Phrases.init_from_db()
	$TabBar/Fills.init_from_db()
	$TabBar/Words.init_from_db()
	$TabBar/Kanji.init_from_db()

func _on_db_changed() -> void:
	PracticeDB.save_to_cloud()

func _on_tab_bar_tab_changed(tab: int) -> void:
	for i in $TabBar.get_children():
		if i.get_index() != tab:
			i.visible = false
		else:
			i.visible = true
			if i.has_method("init_filter"):
				print("init_filter")
				i.init_filter()

func _on_jump_to_fills() -> void:
	$TabBar.current_tab = FILLS_TAB_INDEX
	$TabBar/Fills.init_from_db() # new empty fills possibly added

func _on_jump_to_words() -> void:
	$TabBar.current_tab = WORDS_TAB_INDEX
	$TabBar/Words.init_from_db() # new empty words possibly added

func _on_jump_to_kanji() -> void:
	$TabBar.current_tab = KANJI_TAB_INDEX
	$TabBar/Kanji.init_from_db() # new empty kanji possibly added
