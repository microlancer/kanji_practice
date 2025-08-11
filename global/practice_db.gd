extends Node

signal db_loaded
signal db_changed

var phrases: Array = []
var fills: Dictionary = {}
var words: Dictionary = {}
var kanji: Dictionary = {}

var filter_phrases: String = ""
var filter_fills: String = ""
var filter_words: String = ""
var filter_kanji: String = ""

var cloud_url: String = "https://microlancer.io/kanji/index.php?id=123"

func _ready() -> void:
	print("loading from " + cloud_url)
	load_from_cloud()

	db_changed.connect(_on_db_changed)

func _on_db_changed():
	pass

func foo():
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


func save_to_cloud() -> void:
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_post_completed)

	var json_string = get_json_string_from_db()
	var json_bytes = json_string.to_utf8_buffer()

	print("Length of json: " + str(json_bytes.size()))

	# Format like a normal POST form: data=<JSON string>
	#var post_data = "data=" + json_string.percent

	var headers = [
		"Content-Type: application/json; charset=utf-8", # form-encoded body
		"Content-Length: %d" % json_bytes.size()
	]

	var err = http_request.request(
		cloud_url,
		headers,
		HTTPClient.METHOD_POST,
		json_string
	)

	if err != OK:
		print("Error starting POST request:", err)


#func _on_request_completed(result, response_code, headers, body):
	#print("Result:", result)
	#print("HTTP Code:", response_code)
	#print("Body:", body.get_string_from_utf8())

func load_from_cloud() -> void:
	# Create an HTTPRequest node
	var http_request = HTTPRequest.new()
	add_child(http_request)

	# Connect the completion signal
	http_request.request_completed.connect(_on_get_completed)

	# Make the GET request
	var err = http_request.request(cloud_url)
	if err != OK:
		print("Error starting HTTP request: ", err)

func _on_post_completed(result, response_code, _headers, body):
	print("Result: ", result)
	print("HTTP Code: ", response_code)

	if result == OK and response_code == 200:
		var text: String = body.get_string_from_utf8()
		print_rich("Body length: " + str(text.length()))
		print("Body: " + text)
	else:
		print(body.get_string_from_utf8())
		print("Request failed.")

func _on_get_completed(result, response_code, _headers, body):
	print("Result: ", result)
	print("HTTP Code: ", response_code)

	if result == OK and response_code == 200:
		var text = body.get_string_from_utf8()
		print("Body: ", text)
		set_db_from_json_string(text)
	else:
		print("Request failed.")

func set_db_from_json_string(text: String) -> void:
	var data = JSON.parse_string(text)
	phrases = data.phrases
	fills = data.fills
	words = data.words
	kanji = data.kanji
	db_loaded.emit()

func get_json_string_from_db() -> String:
	var all_data: Dictionary = {
		"phrases": phrases,
		"fills": fills,
		"words": words,
		"kanji": kanji
	}
	return JSON.stringify(all_data)

func extract_fills(string: String) -> Array:
	var regex := RegEx.new()
	regex.compile("<(.*?)>")

	var matches := []
	for result in regex.search_all(string):
		# result.get_string(1) is the first capture group (.*?) from the pattern
		matches.append(result.get_string(1))

	return matches

func get_kanji_array(word: String) -> Array:
	var kanji_array: Array = []
	for c in word:
		if JapaneseText.is_kanji(c):
			kanji_array.append(c)
	return kanji_array
