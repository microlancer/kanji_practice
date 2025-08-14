extends Node2D

var _all_strokes_data: Dictionary = {}
var _current_index: int = 0
var _current_char: String = ""
var _current_strokes: Array = []

func _ready() -> void:

	var test: Dictionary = {"a":"b"}
	var test_as_bytes: PackedByteArray = var_to_bytes(test)
	assert(test_as_bytes.size() > 0)
	var check: Dictionary = bytes_to_var(test_as_bytes)
	assert(check.size() > 0)
	assert(test == check)
	var compressed: PackedByteArray = test_as_bytes.compress(FileAccess.COMPRESSION_FASTLZ)
	assert(compressed.size() > 0)
	var uncompressed: PackedByteArray = compressed.decompress(test_as_bytes.size(), FileAccess.COMPRESSION_FASTLZ)
	assert(uncompressed.size() > 2)
	var check2: Dictionary = bytes_to_var(uncompressed)
	assert(test == check2)





	var stroke1 = [Vector2(0, 0), Vector2(30, 40), Vector2(55, 7)]
	var stroke2 = [Vector2(99, 99), Vector2(131, 141), Vector2(156, -108)]
	# Step 1: Process strokes (normalize, simplify, resample)
	var sig1 = StrokeUtils.process_stroke(stroke1, 32, 0.02, true)
	var sig2 = StrokeUtils.process_stroke(stroke2, 32, 0.02, true)

	print(sig1)

	# Step 2: Compare them (using DTW for forgiving alignment)
	var similarity = StrokeUtils.compare_strokes2(sig1, sig2, true, 0.25)

	# Step 3: Interpret similarity score
	#   Assuming compare_strokes returns a 0.0 (identical) to 1.0 (max difference) range
	if similarity < 0.2:
		print("These strokes are equivalent. Score: ", similarity)
	else:
		print("These strokes are different. Score: ", similarity)

	var index = 0
	for char in PracticeDB._kana_draw_data:
		if index == _current_index:
			_current_char = char
			break
		index += 1

	$DrawPanel/Label.text = _current_char

func _on_draw_panel_stroke_drawn(strokeIndex: int, direction: String) -> void:
	pass # Replace with function body.

var _last_sig = null

func _on_draw_panel_stroke_drawn_raw(points: Array) -> void:
	print(points)
	print("normalizing")
	var sig1 = StrokeUtils.process_stroke(points, 32, 0.02, true)
	print(sig1)

	_current_strokes.append(sig1)

	if _last_sig:
		print("Comparing with previous stroke")
		var similarity = StrokeUtils.compare_strokes2(sig1, _last_sig, true, 0.25)

		# Step 3: Interpret similarity score
		#   Assuming compare_strokes returns a 0.0 (identical) to 1.0 (max difference) range
		if similarity < 0.5:
			print("These strokes are equivalent. Score: ", similarity)
		else:
			print("These strokes are different. Score: ", similarity)

	_last_sig = sig1

	pass # Replace with function body.


func _on_button_pressed() -> void:
	$DrawPanel.clear()
	pass # Replace with function body.


func _on_done_pressed() -> void:
	print(_current_char)
	var data: Dictionary = {""+_current_char:_current_strokes}
	var json_string: String = JSON.stringify(data)
	#print(json_string)
	$TextEdit.text = json_string
	_current_strokes = []
	pass # Replace with function body.
