extends Node

signal db_loaded
signal db_changed

enum MasteryType { MASTERY_READ, MASTERY_WRITE }

var phrases: Array = []
var fills: Dictionary = {}
var words: Dictionary = {}
var kanji: Dictionary = {}
var kana: Dictionary = {}

var filter_phrases: String = ""
var filter_fills: String = ""
var filter_words: String = ""
var filter_kanji: String = ""
var filter_kana: String = ""

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
		#print("Body: " + text)
	else:
		print(body.get_string_from_utf8())
		print("Request failed.")

func _on_get_completed(result, response_code, _headers, body):
	print("Result: ", result)
	print("HTTP Code: ", response_code)

	if result == OK and response_code == 200:
		var text = body.get_string_from_utf8()
		#print("Body: ", text)
		set_db_from_json_string(text)
	else:
		print("Request failed.")

func set_db_from_json_string(text: String) -> void:
	var data = JSON.parse_string(text)
	phrases = data.phrases
	fills = data.fills
	words = data.words
	kanji = data.kanji
	kana = data.kana
	db_loaded.emit()

func get_json_string_from_db() -> String:
	var all_data: Dictionary = {
		"phrases": phrases,
		"fills": fills,
		"words": words,
		"kanji": kanji as Dictionary,
		"kana": kana as Dictionary
	}
	return JSON.stringify(all_data)

func extract_fills(string: String) -> Array:
	print("Extracting fills from: " + string)
	var regex := RegEx.new()
	regex.compile("([a-z\\-]+)")

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

func get_draw_data_for_kana(c: String) -> String:
	if c not in kana:
		print_debug("Cannot find kana: " + c)
		return ""
	return kana[c].draw_data

func get_draw_data_for_kanji(k: String) -> String:
	if k not in kanji:
		print_debug("Cannot find kanji: " + k)
		return ""
	return kanji[k].draw_data

func encode_all_strokes(all_strokes: Array) -> String:
	var bytes: PackedByteArray = var_to_bytes(all_strokes)
	if not bytes:
		print("Unable to serialize: " + str(bytes.size()))
		return ""
	#var use_compression = false
	var base64: String = ""
	#if use_compression:
		#var compressed: PackedByteArray = bytes.compress(FileAccess.COMPRESSION_ZSTD)
		#if not compressed:
			#print("Unable to compress: " + str(bytes.size()))
			#return ""
		#base64 = Marshalls.raw_to_base64(compressed)

	base64 = Marshalls.raw_to_base64(bytes)
	if base64 == "":
		print("Unable to base 64 encode: " + str(bytes.size()))
		return ""
	#return {
		#"original_size": bytes.size(),
		#"base64": base64
	#}
	return base64
	#return compressed.to_base64()

func decode_all_strokes(base64: String) -> Array:
	print("base64-len: " + str(base64.length()))
	if base64 == "":
		print("No string to decode")
		return []
	var uncompressed: PackedByteArray = Marshalls.base64_to_raw(base64)
	var all_strokes: Variant = bytes_to_var(uncompressed)
	if all_strokes == null:
		print("Unable to convert bytes to var: " + str(base64.length))
		return []
	return all_strokes

func get_valid_data() -> Dictionary:
	var valid_phrases: Array = []
	var valid_fills: Dictionary = {} # same fill can be in many phrases
	var valid_words: Dictionary = {} # same word can be in many fills
	for phrase in phrases:
		var extracted_fills: Array = extract_fills(phrase)
		var is_valid_phrase: bool = true
		var valid_words_for_phrase: Array = []
		var valid_fills_for_phrase: Array = []
		for fill in extracted_fills:
			if fill not in fills:
				is_valid_phrase = false
				break
			var extracted_words: Array = fills[fill].words
			for word in extracted_words:
				if JapaneseText.has_kanji(word):
					if word not in words:
						is_valid_phrase = false
						break
					elif words[word].furigana == "":
						is_valid_phrase = false
						break
				else:
					# No kanji in word, skip to next word
					continue
				var extracted_kanji: Array = get_kanji_array(word)
				for k in extracted_kanji:
					if k not in kanji:
						is_valid_phrase = false
						break
					elif kanji[k].draw_data == "":
						is_valid_phrase = false
						break
				valid_words_for_phrase.append(word)
			valid_fills_for_phrase.append(fill)
		if is_valid_phrase:
			valid_phrases.append(phrase)
			for word in valid_words_for_phrase:
				valid_words[word] = true
			for fill in valid_fills_for_phrase:
				valid_fills[fill] = true
	return {
		"phrases": valid_phrases,
		"fills": valid_fills.keys(),
		"words": valid_words.keys()
	}

func increment_mastery_for_word(word: String, type: MasteryType) -> void:
	if "mastery_read" not in PracticeDB.words[word]:
		words[word]["mastery_read"] = 0
		words[word]["mastery_write"] = 0

	if type == MasteryType.MASTERY_READ:
		words[word].mastery_read += 1
		var add_seconds: int = int(pow(2, words[word].mastery_read))
		print("Setting read mastery for word " + word + " to be due in " +\
			str(add_seconds) + " seconds at level " + str(words[word].mastery_read))
		words[word].due_read = int(Time.get_unix_time_from_system()) +\
			add_seconds
	else:
		words[word].mastery_write += 1
		var add_seconds: int = int(pow(2, words[word].mastery_write))
		print("Setting write mastery for word " + word + " to be due in " +\
			str(add_seconds) + " seconds at level " + str(words[word].mastery_write))
		words[word].due_write = int(Time.get_unix_time_from_system()) +\
			add_seconds

	save_to_cloud()

func reset_mastery_for_word(word: String, type: MasteryType) -> void:
	if "mastery_read" not in PracticeDB.words[word]:
		words[word]["mastery_read"] = 0
		words[word]["mastery_write"] = 0

	if type == MasteryType.MASTERY_READ:
		words[word].mastery_read = 0
		var add_seconds: int = int(pow(2, words[word].mastery_read))
		print("Setting read mastery for word " + word + " to be due in " +\
			str(add_seconds) + " seconds at level " + str(words[word].mastery_read))
		words[word].due_read = int(Time.get_unix_time_from_system()) +\
			add_seconds
	else:
		words[word].mastery_write = 0
		var add_seconds: int = int(pow(2, words[word].mastery_write))
		print("Setting write mastery for word " + word + " to be due in " +\
			str(add_seconds) + " seconds at level " + str(words[word].mastery_write))
		words[word].due_write = int(Time.get_unix_time_from_system()) +\
			add_seconds

	save_to_cloud()

func select_due(valid_words: Array) -> Dictionary:
	var due_dates_by_word: Array = get_due_dates_for_words(valid_words)
	#for word in valid_words:
#
		#if "due_read" not in words[word]:
			#words[word]["due_read"] = 0
			#words[word]["due_write"] = 0
#
		#var now = Time.get_unix_time_from_system()
#
		#var sub_word: Dictionary = {
			#"word": word,
			#"mastery_type": MasteryType.MASTERY_READ,
			#"due": int(words[word].due_read),
			#"sec_remain": int(words[word].due_read - now)
		#}
		#due_dates_by_word.append(sub_word)
		#var sub_word2: Dictionary = {
			#"word": word,
			#"mastery_type": MasteryType.MASTERY_WRITE,
			#"due": int(words[word].due_write),
			#"sec_remain": int(words[word].due_write - now)
		#}
		#due_dates_by_word.append(sub_word2)

	due_dates_by_word.sort_custom(_compare_words_due)
	var due_seconds: int = 0
	if due_dates_by_word[0].mastery_type == MasteryType.MASTERY_READ:
		due_seconds = int(Time.get_unix_time_from_system() - due_dates_by_word[0].due)
	else:
		due_seconds = int(Time.get_unix_time_from_system() - due_dates_by_word[0].due)

	return {
		"word": due_dates_by_word[0].word,
		"mastery_type": due_dates_by_word[0].mastery_type,
		"due_seconds": due_seconds
	}

func _compare_words_due(a: Dictionary, b: Dictionary) -> bool:
	if a.due < b.due:
		return true
	return false

func sec_to_remain(seconds: int) -> String:
	var days: int = int(float(seconds) / 86400)
	seconds = seconds % 86400
	var hours: int = int(float(seconds) / 3600)
	seconds = seconds % 3600
	var minutes: int = int(float(seconds) / 60)
	seconds = seconds % 60

	var parts := []
	if days > 0:
		parts.append(str(days) + "d")
	if hours > 0:
		parts.append(str(hours) + "h")
	if minutes > 0:
		parts.append(str(minutes) + "m")
	if seconds > 0 or parts.is_empty():
		parts.append(str(seconds) + "s")

	return " ".join(parts)

func get_due_count(valid_words: Array) -> int:

	var due_words = get_due_dates_for_words(valid_words)
	var count: int = 0
	for word in due_words:
		if word.sec_remain <= 0:
			count += 1
	return count

func get_due_dates_for_words(valid_words: Array) -> Array:
	var due_dates_by_word: Array = []
	for word in valid_words:

		if "due_read" not in words[word]:
			words[word]["due_read"] = 0
			words[word]["due_write"] = 0

		var now: int = int(Time.get_unix_time_from_system())

		var sub_word: Dictionary = {
			"word": word,
			"mastery_type": MasteryType.MASTERY_READ,
			"due": int(words[word].due_read),
			"sec_remain": int(words[word].due_read) - now
		}
		due_dates_by_word.append(sub_word)
		var sub_word2: Dictionary = {
			"word": word,
			"mastery_type": MasteryType.MASTERY_WRITE,
			"due": int(words[word].due_write),
			"sec_remain": int(words[word].due_write) - now
		}
		due_dates_by_word.append(sub_word2)
	return due_dates_by_word


func postpone_due_for_word(word: String, type: MasteryType) -> void:
	if "mastery_read" not in PracticeDB.words[word]:
		words[word]["mastery_read"] = 0
		words[word]["mastery_write"] = 0

	if type == MasteryType.MASTERY_READ:
		#words[word].mastery_read += 1
		var add_seconds: int = int(pow(2, words[word].mastery_read))
		print("Postponing read mastery for word " + word + " to be due in " +\
			str(add_seconds) + " seconds at level " + str(words[word].mastery_read))
		words[word].due_read = int(Time.get_unix_time_from_system()) +\
			add_seconds
	else:
		#words[word].mastery_write += 1
		var add_seconds: int = int(pow(2, words[word].mastery_write))
		print("Postponing write mastery for word " + word + " to be due in " +\
			str(add_seconds) + " seconds at level " + str(words[word].mastery_write))
		words[word].due_write = int(Time.get_unix_time_from_system()) +\
			add_seconds

	save_to_cloud()
