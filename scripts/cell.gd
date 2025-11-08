extends Control
class_name Cell


const GRAY = Color(0.502, 0.502, 0.502)
const ORANGE = Color.ORANGE
const BOMB_LETTER = "B"
const FLAG_LETTER = "F"

var is_bomb : bool
var _has_flag : bool = false
var _content : String = ""


func set_content(content: int):
	if content == preload("res://scripts/generator_instance.gd").BOMB:
		_content = BOMB_LETTER
		is_bomb = true
		#$ColorRect2.color = Color.RED
	else:
		_content = str(content)
		is_bomb = false


func reveal_cell(recurse: bool = true):
	$ColorRect2.color = GRAY
	$Content.text = _content
	if not is_revealed():
		EventBus.cell_revealed.emit(self)
	$Content.show()

	if _content == "0" and recurse:
		for group in get_groups():
			get_tree().call_group(group, "reveal_cell", false)


func is_revealed():
	return $Content.visible and $Content.text != FLAG_LETTER


func reset_cell():
	$Content.hide()
	$Content.text = FLAG_LETTER


func _gui_input(event):
	if event is InputEventScreenTouch:
		if not _has_flag:
			if is_revealed():
				event.canceled = true
				return
			
			if event.double_tap:
				reveal_cell()
				return
			
		if event.is_pressed():
			$TapTimer.start()
		else:
			$TapTimer.stop()
		
		
func _toggle_flag():
	_has_flag = not _has_flag
	$Content.visible = _has_flag
	if _has_flag:
		$ColorRect2.color = ORANGE
		EventBus.flag_placed.emit()
	else:
		$ColorRect2.color = GRAY
		EventBus.flag_removed.emit()
