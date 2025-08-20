extends Control

const PHRASES_TAB_INDEX = 1
const FILLS_TAB_INDEX = 2
const WORDS_TAB_INDEX = 3
const KANJI_TAB_INDEX = 4

func _ready() -> void:
	$TabBar/Study.jump_to_phrases.connect(_on_jump_to_phrases)
	$TabBar/Phrases.jump_to_fills.connect(_on_jump_to_fills)
	$TabBar/Fills.jump_to_words.connect(_on_jump_to_words)
	$TabBar/Words.jump_to_kanji.connect(_on_jump_to_kanji)

	PracticeDB.db_changed.connect(_on_db_changed)
	PracticeDB.db_loaded.connect(_on_db_loaded)
	PracticeDB.cloud_data_different.connect(_on_cloud_data_different)

func _on_db_loaded() -> void:
	$TabBar/Phrases.init_from_db()
	$TabBar/Fills.init_from_db()
	$TabBar/Words.init_from_db()
	$TabBar/Kanji.init_from_db()
	$TabBar/Kana.init_from_db()

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
			if i.has_method("init_from_db"):
				print("init_from_db")
				i.init_from_db()

func _on_jump_to_fills() -> void:
	$TabBar.current_tab = FILLS_TAB_INDEX
	$TabBar/Fills.init_from_db() # new empty fills possibly added

func _on_jump_to_words() -> void:
	$TabBar.current_tab = WORDS_TAB_INDEX
	$TabBar/Words.init_from_db() # new empty words possibly added

func _on_jump_to_kanji() -> void:
	$TabBar.current_tab = KANJI_TAB_INDEX
	$TabBar/Kanji.init_from_db() # new empty kanji possibly added

func _on_jump_to_phrases() -> void:
	$TabBar.current_tab = PHRASES_TAB_INDEX
	$TabBar/Phrases.init_from_db()


func _on_use_cloud_data_pressed() -> void:
	PracticeDB.use_cloud_data()
	$TabBar/Study._study_started = false
	$TabBar/Study._start_study()
	$CloudPopup.visible = false


func _on_ignore_pressed() -> void:
	$CloudPopup.visible = false

func _on_cloud_data_different() -> void:
	$CloudPopup.visible = true
