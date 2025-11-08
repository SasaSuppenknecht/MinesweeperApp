extends GridContainer

const SAVE_PATH = "user://savegame.save"
const CELL = preload("res://scenes/cell.tscn")
const HIGHLIGHT_CELL = preload("res://scenes/highlight_cell.tscn")
const HIGHTLIGHT_CELL_SCRIPT = preload("res://scripts/highlight_cell.gd")
const GENERATOR_INSTANCE = preload("res://scripts/generator_instance.gd")
const CELL_SIZE = 50
const SEP = 2

const REVEALED = 42
const NOT_REVEALED = 43
const FLAGGED = 44

var _cells_left : int
var _last_revealed : Cell = null

var grid_size := 10
var bomb_count := 30


func _ready():
	_set_separation(SEP)
	EventBus.cell_revealed.connect(_on_cell_revealed)
	
	if FileAccess.file_exists(SAVE_PATH):
		load_data()
	else:
		create_level()


func _set_separation(sep: int):
	add_theme_constant_override("h_separation", sep)
	add_theme_constant_override("v_separation", sep)


func create_level():
	var board := await LevelGenerator.create_grid(grid_size, bomb_count)
	%FlagCounter.set_counter(bomb_count)
	_last_revealed = null
	_cells_left = grid_size ** 2 - bomb_count
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	_build_grid(board)

	
func _build_grid(board: LevelGenerator.Board):
	for child in get_children():
		remove_child(child)
	
	_resize_gameboard(grid_size)
	# Set up field
	for i in grid_size * grid_size:
		var cell: Cell
		if i == board.start_field:
			cell = HIGHLIGHT_CELL.instantiate()
		else: 
			cell = CELL.instantiate()
		cell.set_content(board.grid[i])
		add_child(cell)
		#cell.reveal_cell(false)
		
	# Prepare reveal of zero groups
	var id := 0
	var children := get_children()
	for zero_area in board.zero_areas:
		for cell in zero_area:
			children[cell].add_to_group("area" + str(id))
		id += 1


func _resize_gameboard(length: int):
	# size and positioning
	var grid_size_pixel = length * CELL_SIZE + SEP * (CELL_SIZE - 1)
	size = Vector2(grid_size_pixel, grid_size_pixel)
	columns = length
	@warning_ignore("integer_division")
	var center = Vector2(grid_size_pixel / 2, grid_size_pixel / 2)
	position = -center


func _on_cell_revealed(cell: Cell):
	if not cell.is_bomb:
		_cells_left -= 1
		if _cells_left == 0:
			EventBus.game_won.emit()
	else:
		_last_revealed = cell
		EventBus.game_over.emit()


func undo_reveal():
	_last_revealed.reset_cell()


func _notification(what):
	if what == NOTIFICATION_APPLICATION_PAUSED:
		save_data()


func save_data():
	var save_file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	save_file.store_16(grid_size)
	save_file.store_16(bomb_count)
	var index_start_cell : int = -1
	var group_to_index : Dictionary[String, PackedInt32Array] = {}
	for i in get_children().size():
		var child : Cell = get_children()[i]
		if child is HIGHTLIGHT_CELL_SCRIPT:
			index_start_cell = i
		if child._content == Cell.BOMB_LETTER:
			save_file.store_8(GENERATOR_INSTANCE.BOMB)
		else:
			save_file.store_8(int(child._content))
		if child.is_revealed():
			save_file.store_8(REVEALED)
		elif child._has_flag:
			save_file.store_8(FLAGGED)
		else:
			save_file.store_8(NOT_REVEALED)
		for group in child.get_groups():
			if not group_to_index.has(group):
				group_to_index[group] = PackedInt32Array()
			group_to_index[group].append(i)
	save_file.store_16(index_start_cell)
	save_file.store_8(group_to_index.keys().size())
	for key in group_to_index.keys() as Array[String]:
		if not key.begins_with("area"):
			continue
		save_file.store_16(group_to_index[key].size())
		for index in group_to_index[key] as PackedInt32Array:
			save_file.store_16(index)
	save_file.close()


func load_data():
	var save_file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	grid_size = save_file.get_16()
	bomb_count = save_file.get_16()
	_cells_left = grid_size ** 2 - bomb_count
	%FlagCounter.set_counter(bomb_count)
	_resize_gameboard(grid_size)
	for i in grid_size * grid_size:
		var cell : Cell = CELL.instantiate()
		cell.set_content(save_file.get_8())
		var state := save_file.get_8()
		if state == REVEALED:
			cell.reveal_cell(false)
		elif state == FLAGGED:
			cell._toggle_flag()
		add_child(cell)
	var index_start_cell := save_file.get_16()
	var start_cell : Cell = get_children()[index_start_cell]
	if not start_cell.is_revealed():
		var highlighted_cell : Cell = HIGHLIGHT_CELL.instantiate()
		highlighted_cell._content = start_cell._content
		remove_child(start_cell)
		add_child(highlighted_cell)
		move_child(highlighted_cell, index_start_cell)
	var number_of_groups := save_file.get_8()
	for id in number_of_groups:
		var group_name := "area" + str(id)
		var number_of_members := save_file.get_16()
		for i in number_of_members:
			var cell_index := save_file.get_16()
			get_children()[cell_index].add_to_group(group_name)
	save_file.close()
