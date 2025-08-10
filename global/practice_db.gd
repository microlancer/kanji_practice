extends Node

var phrases: Array = []
var lists: Dictionary = {}
var words: Dictionary = {}
var kanji: Dictionary = {}

var filter_phrases: String = ""
var filter_lists: String = ""
var filter_words: String = ""
var filter_kanji: String = ""

func _ready() -> void:
	phrases = [
		"<place>の<subarea>で<verbing>"
	]

	lists = {
		"place": {
			"words": ["駅","家","会社","公園","自宅"],
			"phrases": [0],
		},
		"subarea": {
			"words": ["前"],
			"phrases": [0],
		},
		"verbing": {
			"words": ["待っている"],
			"phrases": [0],
		},
		"person": {
			"words": ["田中さん","マイケルくん"],
			"phrases": [],
		},
		"edible": {
			"words": ["チキン","ラーメン","お寿司"],
			"phrases": [],
		},
		"food-adj": {
			"words": ["おいしいな","辛いな","冷たいな","熱いな"],
			"phrases": [],
		}
	}

	words = {
		"駅": {
			"furigana": "えき",
			"mastery": 0,
			"lists": ["place"]
		},
		"前": {
			"furigana": "まえ",
			"mastery": 0,
			"lists": ["place"]
		},
		"待": {
			"furigana": "ま",
			"mastery": 0,
			"lists": []
		},
		"待っている": {
			"furigana": "まっている",
			"mastery": 0,
			"lists": ["place"]
		}
	}

	kanji = {
		"駅": {
			"draw_data": []
		},
		"前": {
			"draw_data": []
		},
		"待": {
			"draw_data": []
		}
	}

func set_button_color(button: Button, color: Color) -> void:
	button.add_theme_color_override("font_color", color)
	button.add_theme_color_override("font_pressed_color", color)
	button.add_theme_color_override("font_focus_color", color)
	button.add_theme_color_override("font_hover_color", color)
