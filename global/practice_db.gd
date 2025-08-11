extends Node

var phrases: Array = []
var fills: Dictionary = {}
var words: Dictionary = {}
var kanji: Dictionary = {}

var filter_phrases: String = ""
var filter_fills: String = ""
var filter_words: String = ""
var filter_kanji: String = ""

func _ready() -> void:
	phrases = [
		"<place>の<subarea>で<verbing>"
	]

	fills = {
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
			"fills": ["place"]
		},
		"前": {
			"furigana": "まえ",
			"mastery": 0,
			"fills": ["place"]
		},
		"待": {
			"furigana": "ま",
			"mastery": 0,
			"fills": []
		},
		"待っている": {
			"furigana": "まっている",
			"mastery": 0,
			"fills": ["place"]
		}
	}

	kanji = {
		"駅": {
			"draw_data": [],
			"words": ["駅"]
		},
		"前": {
			"draw_data": [],
			"words": ["前"]
		},
		"待": {
			"draw_data": [],
			"words": ["待", "待っている"]
		}
	}
