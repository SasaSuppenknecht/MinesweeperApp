extends Control
class_name Cell

@export var state: Field = Field.BLANK:
	set(value):
		($Sprite2D.texture as AtlasTexture).region.position.x = value * TEXTURE_SIZE
		state = value

enum Field {
	BLANK, FLAG, ZERO, ONE, TWO, THREE, FOUR, FIVE, SIX, SEVEN, EIGHT, BOMB
}

const TEXTURE_SIZE = 100
const BASE_NUMBER_OFFSET = 2
const BOMB = 9

var _has_flag: bool = false
var _content: int = -1

static var tap_start_position: Vector2
static var start_cell: Cell = null


func set_content(content: int):
	if content == BOMB:
		_content = BOMB
	else:
		_content = content


func reveal_cell(recurse: bool = true):
	if not is_revealed():
		if self == start_cell:
			remove_child(get_child(0))
		EventBus.cell_revealed.emit(self )
	
	if _content == BOMB:
		state = Field.BOMB
	else:
		state = (BASE_NUMBER_OFFSET + _content) as Field

	if _content == 0 and recurse:
		for group in get_groups():
			if group.begins_with("_"):
				continue
			get_tree().call_group(group, "reveal_cell", false)


func make_start_cell():
	var colorRect := ColorRect.new()
	colorRect.color = Color.ORANGE
	colorRect.size = Vector2(56, 56)
	colorRect.position = Vector2(-3, -3)
	colorRect.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(colorRect)
	move_child(colorRect, 0)
	start_cell = self


func hides_bomb():
	return _content == BOMB


func is_revealed():
	return state != Field.BLANK && state != Field.FLAG


func reset_cell():
	state = Field.BLANK


func _input(event):
	if not $TapTimer.is_stopped():
		if event is InputEventScreenDrag:
			if tap_start_position.distance_squared_to(event.position) > 20:
				$TapTimer.stop()
		elif event is InputEventPanGesture:
			$TapTimer.stop()


func _gui_input(event):
	if event is InputEventScreenTouch:
		accept_event()
		if not _has_flag:
			if is_revealed():
				event.canceled = true
				return
			
			if event.double_tap:
				reveal_cell()
				return
			
		if event.is_pressed():
			tap_start_position = get_global_transform_with_canvas() * event.position
			$TapTimer.start()
		else:
			$TapTimer.stop()
		
		
func _toggle_flag():
	_has_flag = not _has_flag
	if _has_flag:
		state = Field.FLAG
		EventBus.flag_placed.emit()
	else:
		state = Field.BLANK
		EventBus.flag_removed.emit()
