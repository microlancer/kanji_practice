extends ItemList

var pressed_item: int = -1
var is_dragging := false
const DRAG_THRESHOLD := 10.0
var last_touch_pos: Vector2

var velocity := Vector2.ZERO
const FRICTION := 0.9

var active_touches := {}

func _gui_input(event: InputEvent) -> void:
	# --- Touch input handling ---
	if event is InputEventScreenTouch:
		if event.pressed:
			accept_event()  # prevent built-in press selection

			active_touches[event.index] = true

			pressed_item = get_item_at_position(event.position)
			last_touch_pos = event.position
			is_dragging = false
			velocity = Vector2.ZERO

		else:
			if not active_touches.has(event.index):
				return
			active_touches.erase(event.index)

			if not is_dragging and pressed_item != -1:
				var released_item = get_item_at_position(event.position)
				if released_item == pressed_item:
					select(pressed_item)
					emit_signal("item_selected", pressed_item)
			pressed_item = -1
			is_dragging = false

	elif event is InputEventScreenDrag:
		if not active_touches.has(event.index):
			return

		if not is_dragging and event.position.distance_to(last_touch_pos) > DRAG_THRESHOLD:
			is_dragging = true

		if is_dragging:
			accept_event()  # prevent built-in drag selection changes
			var sc = get_parent() as ScrollContainer
			if sc:
				sc.scroll_vertical -= event.relative.y
				sc.scroll_horizontal -= event.relative.x
				velocity = event.relative / get_process_delta_time()

	elif event is InputEventMouseButton:
		if event.pressed:
			accept_event()  # prevent built-in press selection

	# --- Mouse input handling ---
	elif false and event is InputEventMouseButton:
		if event.pressed:
			accept_event()  # prevent built-in press selection

			pressed_item = get_item_at_position(event.position)
			last_touch_pos = event.position
			is_dragging = false
			velocity = Vector2.ZERO

		else:
			print("check release")
			if not is_dragging and pressed_item != -1:
				var released_item = get_item_at_position(event.position)
				if released_item == pressed_item:
					print("Selecting item")
					select(pressed_item)
					emit_signal("item_selected", pressed_item)
			pressed_item = -1
			is_dragging = false

func _process(delta: float) -> void:
	if not is_dragging and velocity.length() > 1:
		var sc = get_parent() as ScrollContainer
		if sc:
			sc.scroll_vertical -= velocity.y * delta
			sc.scroll_horizontal -= velocity.x * delta
			velocity *= pow(FRICTION, delta * 60)
