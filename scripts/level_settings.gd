extends ConfirmationDialog


func _ready():
	(%GridSize.get_line_edit() as LineEdit).virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER_DECIMAL
	(%BombCount.get_line_edit() as LineEdit).virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER_DECIMAL


func _on_confirmed():
	%GameBoard.grid_size = %GridSize.value
	%GameBoard.bomb_count = %BombCount.value
	%GameBoard.create_level()


func _on_canceled():
	hide()


func _on_about_to_popup():
	%GridSize.value = %GameBoard.grid_size 
	%BombCount.value = %GameBoard.bomb_count


func _on_grid_size_value_changed(value: float) -> void:
	%BombCount.max_value = minf(0.42 * value * value, 1000)


func _on_settings_pressed():
	popup_centered()
