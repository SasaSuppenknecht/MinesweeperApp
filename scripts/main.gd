extends Control

func _ready():
	EventBus.game_won.connect(_on_game_won)
	EventBus.game_over.connect(_on_game_over)
	
	
func _on_game_won():
	var accept_dialog := AcceptDialog.new()
	accept_dialog.dialog_text = "Game Won!"
	_configure_dialog(accept_dialog)
	
	
func _on_game_over():
	var confirmation_dialog := ConfirmationDialog.new()
	confirmation_dialog.dialog_text = "Game Over!"
	confirmation_dialog.cancel_button_text = "Continue"
	confirmation_dialog.canceled.connect(%GameBoard.undo_reveal)
	
	_configure_dialog(confirmation_dialog)


func _configure_dialog(dialog: AcceptDialog):
	dialog.get_label().horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialog.ok_button_text = "New Game"
	dialog.title = ""
	dialog.dialog_close_on_escape = false
	dialog.add_theme_icon_override("close", PlaceholderTexture2D.new())
	dialog.unfocusable = true
	
	dialog.confirmed.connect($%GameBoard.create_level)
	add_child(dialog)
	move_child(dialog, 0)
	dialog.popup_centered(Vector2i(50, 50))
