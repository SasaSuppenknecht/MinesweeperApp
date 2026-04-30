extends Camera2D


const MIN_ZOOM = Vector2(0.2, 0.2)
const MAX_ZOOM = Vector2(2.5, 2.5)

const CAMERA_LIMIT_MARGIN = Vector2(100, 100)

func _input(event):
	if event is InputEventMagnifyGesture:
		zoom = (event.factor * zoom).clamp(MIN_ZOOM, MAX_ZOOM)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = (0.9 * zoom).clamp(MIN_ZOOM, MAX_ZOOM)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = (1.1 * zoom).clamp(MIN_ZOOM, MAX_ZOOM)
		get_viewport().set_input_as_handled()
	if event is InputEventScreenDrag:
		position -= event.relative * 1 / zoom
		get_viewport().set_input_as_handled()


func _ready():
	%GameBoard.level_created.connect(_set_camera_boundary)

@warning_ignore_start("narrowing_conversion")
func _set_camera_boundary():
	var pos : Vector2 = %GameBoard.position - CAMERA_LIMIT_MARGIN
	limit_left = pos.x
	limit_top = pos.y
	limit_right = -pos.x
	limit_bottom = -pos.y
@warning_ignore_restore("narrowing_conversion")
