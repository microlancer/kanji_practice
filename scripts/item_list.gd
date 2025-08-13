extends ItemList

var last_touch_pos: Vector2
var is_dragging := false
const DRAG_THRESHOLD := 10.0  # pixels

var velocity := Vector2.ZERO
const FRICTION := 0.9

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			last_touch_pos = event.position
			is_dragging = false
			velocity = Vector2.ZERO  # reset velocity when new touch starts
		else:
			# Touch released — stop dragging
			is_dragging = false

	elif event is InputEventScreenDrag:
		if not is_dragging and event.position.distance_to(last_touch_pos) > DRAG_THRESHOLD:
			is_dragging = true

		if is_dragging:
			var sc = get_parent() as ScrollContainer
			if sc:
				# Move scroll container by drag delta
				sc.scroll_vertical -= event.relative.y
				sc.scroll_horizontal -= event.relative.x

				# Calculate velocity (pixels per second)
				velocity = event.relative / get_process_delta_time()
			accept_event()  # prevent selection change while dragging

func _process(delta: float) -> void:
	if not is_dragging:
		var sc = get_parent() as ScrollContainer
		if sc and velocity.length() > 1:
			# Apply inertia movement
			sc.scroll_vertical -= velocity.y * delta
			sc.scroll_horizontal -= velocity.x * delta

			# Apply friction to slow down velocity
			velocity *= pow(FRICTION, delta * 60)
