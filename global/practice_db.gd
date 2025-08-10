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
			"words": ["駅"],
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
