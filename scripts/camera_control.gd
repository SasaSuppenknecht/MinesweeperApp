extends Camera2D


const MIN_ZOOM = Vector2(0.5, 0.5)
const MAX_ZOOM = Vector2(2, 2)

# TODO:
# Lockout long click on field when panning or zooming
# Pan Speed should scale with zoom factor

func _input(event):
	if event is InputEventMagnifyGesture:
		zoom = (event.factor * zoom).clamp(MIN_ZOOM, MAX_ZOOM)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = (0.9 * zoom).clamp(MIN_ZOOM, MAX_ZOOM)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = (1.1 * zoom).clamp(MIN_ZOOM, MAX_ZOOM)
	if event is InputEventScreenDrag:
		position -= event.relative
		get_viewport().set_input_as_handled()
