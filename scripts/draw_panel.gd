class_name DrawPanel
extends Panel

# DrawPanel is a Panel that allows for drawing (with mouse
# or touch) and originally designed for detecting when kanji characters are
# written. For each stroke, a stroke_drawn signal is emitted.
# When the event is fired, it will also pass along the directional type of
# stroke as follows:
#   DR = Down Right      DL = Down Left     UR = Up Right     UL = Up Left
#   DD = Down (Straight)                    UU = Up (Straight)
#   RD = Right Down      RU = Right Up      LD = Left Down    LU = Left Up
#   RR = Right (Straight)                   LL = Left (Straight)
#
# For angled strokes (DR,DL,UR,UL,RD,RU,LD,LU) the determining factor is that
# The length of the second stroke is beyond half of the first stroke. In some
# cases, this is too tight, so it's better to use D*, U*, R*, L* in these
# sitations which will allow for detecting any of them as success.
#
# Some strokes like the dot can be finicky, so a ** stroke meaning anything
# can be useful.

var prev_point = Vector2.ZERO

var strokeIndex: int = 0
var strokes = [[]]
var alreadyDrawnIndex = -1
var antialiasing = true
var brush_color = Color.WHITE_SMOKE #Color.GOLDENROD
var brush_width = 10
var minimum_point_distance = 5
var enabled = true
var _requested_clear: bool = false
#var _requested_refresh: bool = false
@export var uncap_fps_on_enable: bool = false
var _old_fps: int

signal stroke_drawn(strokeIndex: int, direction: String)

func _ready():
	Input.set_use_accumulated_input(false)
	_old_fps = Engine.max_fps
	pass

func end_stroke():
	if strokes[strokeIndex].size() == 0:
		# Skip this function if there's no stroke in progress.
		return
	queue_redraw()
	var direction = calculate_stroke(strokes[strokeIndex])
	#print(direction)
	print("emitting strokeIndex: " + str(strokeIndex))
	stroke_drawn.emit(strokeIndex, direction)

	# since clear() setting strokeIndex during emit will be overwritten here,
	# we will check if that was called and intended to be reset
	if _requested_clear:
		strokeIndex = 0
		_requested_clear = false
	else:
		# continue with the next new stroke
		print("Incrementing stroke index")
		strokeIndex += 1

	print("Starting next stroke with empty array")
	strokes.append([])

	if uncap_fps_on_enable:
		print("Resetting FPS to: " + str(_old_fps))
		Engine.max_fps = _old_fps
	await get_tree().process_frame
	_handling_end = false

var _handling_end: bool = false
var _is_drawing: bool = false

func _gui_input(event):

	if !enabled:
		#print("disabled")
		return

	if is_out_of_bounds(event.position):
		# skip events happening outside of the drawing area
		#print("out of bounds")
		return

	if not _is_drawing and event is InputEventMouseMotion:
		#print("Motion velocity: " + str(event.velocity))
		return

	if event is InputEventScreenTouch:
		print("Touch index: " + str(event.index))
		# Ignore release events with zero touch points (ghost events)
		if not event.pressed and event.index <= 0:
			return



	if not _handling_end and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):

		if (strokes[strokeIndex].size() > 0):
			_handling_end = true
			_is_drawing = false
			print("event="+event.as_text())
			end_stroke()
			queue_redraw()
		#_circle_pos = []
		return

	# skip points too close to each other
	if strokes[strokeIndex].size() > 1:
		#print(event.position)
		#print(strokes[strokeIndex][-1])
		var distance = event.position.distance_to(strokes[strokeIndex][-1])
		if distance < minimum_point_distance:
			#print('skip')
			return

	#print("Adding position")
	_is_drawing = true
	strokes[strokeIndex].append(event.position)
	if uncap_fps_on_enable and Engine.max_fps > 0:
		print("Uncapping FPS")
		Engine.max_fps = 0
	queue_redraw()

func is_out_of_bounds(point):
	var margin = 4
	var out_of_bounds = point.x < margin or point.y < margin \
		or point.x > self.size.x - margin or point.y > self.size.y - margin
	return out_of_bounds

func refresh():
	_draw()

func _draw():

	for loopStrokeIndex in range(strokes.size()):

		var stroke = strokes[loopStrokeIndex]

		if stroke.size() <= 1:
			continue;

		#print([loopStrokeIndex, alreadyDrawnIndex])
		if false and loopStrokeIndex <= alreadyDrawnIndex:
			continue

		for point_index in range(stroke.size()):
			var point = stroke[point_index]
			if is_out_of_bounds(point):
				continue;
			if point_index == 0:
				draw_circle(point, brush_width - 3, brush_color)
			elif point_index == stroke.size()-1:
				draw_line(prev_point, point, brush_color, brush_width, antialiasing)
				draw_circle(point, brush_width - 3, brush_color)
			else:
				draw_line(prev_point, point, brush_color, brush_width, antialiasing)
			prev_point = point

	alreadyDrawnIndex = strokes.size() - 2

	return

# Every collection of points can be converted into one of the following
# vector strokes.
# down (A), right (B), down-left (C), down-right (D),
# right-down corner (E), down-right corner (F)
# We calculate the bounding box based on the longest X or Y distance
# between any two vectors.
func calculate_stroke(points):

	if points.size() == 0:
		return

	var total_x = abs(points[-1].x - points[0].x)
	var total_y = abs(points[-1].y - points[0].y)
	var max_size = max(total_x, total_y)
	var half_size = int(max_size / 2)

	#print([total_x, total_y, max_size, half_size])

	var moved_more_than_half_right = points[-1].x - points[0].x > half_size
	var moved_more_than_half_left = points[0].x - points[-1].x > half_size
	var moved_more_than_half_down = points[-1].y - points[0].y > half_size
	var moved_more_than_half_up = points[0].y - points[-1].y > half_size

	var direction = ""

	if moved_more_than_half_right and moved_more_than_half_down:
		direction = "DR"
	elif moved_more_than_half_left and moved_more_than_half_down:
		direction = "DL"
	elif moved_more_than_half_right and moved_more_than_half_up:
		direction = "UR"
	elif moved_more_than_half_left and moved_more_than_half_up:
		direction = "UL"
	elif moved_more_than_half_right:
		direction = "R"
	elif moved_more_than_half_left:
		direction = "L"
	elif moved_more_than_half_down:
		direction = "D"
	else:
		direction = "U"

	return direction

func _on_mouse_exited() -> void:
	# If the user swipes beyond the drawing area, just end the stroke.
	#print("exit")
	end_stroke()

func clear():
	print("Setting strokeIndex to 0")
	strokeIndex = 0
	strokes = [[]]
	Input.set_use_accumulated_input(false)
	alreadyDrawnIndex = -1
	print("strokeIndex: " + str(strokeIndex))
	_requested_clear = true
	_handling_end = false
	_is_drawing = false
	queue_redraw()

# this is just an example of how to clear the draw panel
func _on_button_button_down() -> void:
	clear()

func disable():
	enabled = false
	if uncap_fps_on_enable:
		print("Resetting FPS to: " + str(_old_fps))
		Engine.max_fps = _old_fps

func enable():
	enabled = true
