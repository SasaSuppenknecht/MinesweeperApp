extends RefCounted


const BOMB = -13
const NO_KNOWLEDGE = -12

const INITIAL_BOMB_FACTOR = 0.05

var rng : RandomNumberGenerator

# Global variables to avoid passing around values to helper functions
var _grid := PackedInt32Array()
var _tried_bombs := PackedInt32Array()
var _size : int
var _number_of_cells : int
var _surrounding_neighbours: Array[PackedInt32Array]

var running := true

func _init():
	rng = RandomNumberGenerator.new()
	rng.randomize()
	#rng.seed = 42

@warning_ignore_start("narrowing_conversion")
func create_grid(size: int, number_of_bombs: int, result_callback: Callable, surrounding_neighbours : Array[PackedInt32Array]) -> void:
	assert(size >= 5)
	assert(number_of_bombs > 0)
	assert(number_of_bombs < size * size)
	
	_size = size
	_number_of_cells = size * size
	_surrounding_neighbours = surrounding_neighbours
	_grid.resize(_number_of_cells)
	
	
	var start_field : int
	
	var start = Time.get_ticks_usec()

	while running:
		start_field = _build_grid(number_of_bombs)
		if _is_solvable(start_field, number_of_bombs):
			break

	print("true")
		
	if running:
		var end = Time.get_ticks_usec()
		print("Time: " + str((end - start) / 1000))
		var zero_areas : Array[PackedInt32Array] = []
		var unprocessed_zeros := PackedInt32Array()
		for cell in _number_of_cells:
			if _grid[cell] == 0:
				unprocessed_zeros.append(cell)
		while not unprocessed_zeros.is_empty():
			var current = unprocessed_zeros[0]
			unprocessed_zeros.remove_at(0)
			var result = _reveal_zero_area(current)
			zero_areas.append(result[0] + result[1])
			for z in result[0]:
				unprocessed_zeros.erase(z)
		result_callback.call(LevelGenerator.Board.new(_grid.duplicate(), start_field, zero_areas))
	_grid.clear()
	_tried_bombs.clear()


func _build_grid(number_of_bombs: int) -> int:
	# Reset grid
	_grid.fill(0)
	_tried_bombs.clear()
	
	for i in [4, 6, 8, 13, 39, 58, 61, 63, 66, 76]:
		_grid[i] = BOMB
		
	for i in _number_of_cells:
		# No reason to count neighbours of bomb fields
		if _grid[i] == BOMB:
			continue
		var neighbours = _surrounding_neighbours[i]
		for n in neighbours:
			if _grid[n] == BOMB:
				_grid[i] += 1
	return 0
	# Pick a field that is not at the edge
	var start_field := rng.randi_range(_size + 1, _number_of_cells - _size - 2)
	# Determine starting area (eight fields around start_field)
	var start_area := [start_field]
	start_area.append_array(_surrounding_neighbours[start_field])
	
	# Place bombs at random locations that ...
	var bomb_count := 0
	while bomb_count < number_of_bombs:
		var bomb_index := rng.randi_range(0, _number_of_cells - 1)
		# ... are not part of the starting area
		if start_area.has(bomb_index):
			continue
		# ... do not already contain a bomb
		if _grid[bomb_index] == BOMB:
			continue
		var bomb_bias := 0.0
		var axis_neighbours := _get_axis_neighbours(bomb_index)
		for n in _surrounding_neighbours[bomb_index]:
			if n in axis_neighbours:
				bomb_bias += 0.2
			else:
				bomb_bias += 0.1
		if rng.randf() < bomb_bias:
			continue
		_grid[bomb_index] = BOMB
		_tried_bombs.append(bomb_index)
		bomb_count += 1
		
	# Set neighbour bomb counts
	for i in _number_of_cells:
		# No reason to count neighbours of bomb fields
		if _grid[i] == BOMB:
			continue
		var neighbours = _surrounding_neighbours[i]
		for n in neighbours:
			if _grid[n] == BOMB:
				_grid[i] += 1
	
	return start_field
	
	
func _add_bomb(start_field: int) -> int:
	var bomb_index := -1
	var start_area := _surrounding_neighbours[start_field] + PackedInt32Array([start_field])
	while true:
		bomb_index = rng.randi_range(0, _number_of_cells - 1)
		if bomb_index in start_area:
			continue
		if _grid[bomb_index] == BOMB:
			continue
		var bomb_bias := 0.0
		var axis_neighbours := _get_axis_neighbours(bomb_index)
		for n in _surrounding_neighbours[bomb_index]:
			if n in axis_neighbours:
				bomb_bias += 0.2
			else:
				bomb_bias += 0.05
		if rng.randf() < bomb_bias:
			continue
		_grid[bomb_index] = BOMB
		break
	return bomb_index
	
	
func _revert_bomb(bomb_index: int) -> void:
	assert(_grid[bomb_index] == BOMB)
	for n in _surrounding_neighbours[bomb_index]:
		if _grid[n] != BOMB:
			_grid[n] -= 1
	
	
func _is_solvable(start_field: int, bomb_count: int) -> bool:
	var grid_knowledge := PackedInt32Array()
	grid_knowledge.resize(_number_of_cells)
	grid_knowledge.fill(NO_KNOWLEDGE) # No knowledge at first
	
	var work_list := PackedInt32Array()
	
	work_list.append(start_field)
	grid_knowledge[start_field] = 0
	
	var found_bombs : int = 0
	
	while not work_list.is_empty() and running:
		if found_bombs == bomb_count:
			return true
		
		# pop first
		var current = work_list[0] 
		work_list.remove_at(0)
		
		if _grid[current] == 0:
			# If the field shows a 0, then the rest of the zeros and bordering
			# valuse are revealing using BFS
			var revealed_area := _reveal_zero_area(current)
			var zeros := revealed_area[0]
			# Zero fields are just taken and stored into grid_knowledge but do not 
			# provide further information and therefore not added to work_list
			for z in zeros:
				grid_knowledge[z] = 0
			# Continous areas of 0 are stored for later use
			var border := revealed_area[1]
			# The border values are revealed 
			for b in border:
				grid_knowledge[b] = _grid[b]
				# The new value might provide further information and is added to 
				# the work_list, if it is not already present 
				if b not in work_list:
					work_list.append(b)
		else: # different positive number
			var result := _check_patterns(current, grid_knowledge)
			# These cells are safe for revealing
			var new_safe_cells := result[0]
			for cell in new_safe_cells:
				grid_knowledge[cell] = _grid[cell]
				if cell not in work_list:
					work_list.append(cell)
				for n in _surrounding_neighbours[cell]:
					if n not in work_list:
						work_list.append(n)
			# These cells are bombs and should be marked as such
			var bombs := result[1]
			# Update the surrounding bomb information
			for bomb in bombs:
				found_bombs += 1
				grid_knowledge[bomb] = BOMB
				var bomb_neighbours := _surrounding_neighbours[bomb]
				for bomb_neighbour in bomb_neighbours:
					if grid_knowledge[bomb_neighbour] != BOMB \
						and grid_knowledge[bomb_neighbour] != NO_KNOWLEDGE \
						and bomb_neighbour != current \
						and bomb_neighbour not in work_list:
						work_list.append(bomb_neighbour)
	print(grid_knowledge)
	return false


func _get_axis_neighbours(index) -> PackedInt32Array:
	var neighbours := _surrounding_neighbours[index]
	var axis_neighbours : PackedInt32Array
	match neighbours.size():
		3:
			axis_neighbours = neighbours.slice(0, 2)
		5:
			axis_neighbours = neighbours.slice(0, 3)
		8:
			axis_neighbours = neighbours.slice(0, 4)
	return axis_neighbours


func _check_patterns(index: int, grid_knowledge: PackedInt32Array) -> Array[PackedInt32Array]:
	var neighbours := _surrounding_neighbours[index]
	# Determine axis neighbours
	var axis_neighbours : PackedInt32Array = _get_axis_neighbours(index)
	# Count unknown cells and bombs containing cells around index
	var unknown_list := PackedInt32Array()
	var bomb_list := PackedInt32Array()
	var remaining_list := PackedInt32Array()
	for n in neighbours:
		var neighbour_value := grid_knowledge[n]
		if neighbour_value == NO_KNOWLEDGE:
			unknown_list.append(n)
		elif neighbour_value == BOMB:
			bomb_list.append(n)
		elif neighbour_value > 0 and n in axis_neighbours:
			remaining_list.append(n)
		
	# Compare field value to list sizes
	var field := grid_knowledge[index]
	var actual_field := field - bomb_list.size()
	if bomb_list.size() > 0 and bomb_list.size() == field:
		# Every neighbouring field cannot be a bomb
		return [unknown_list, PackedInt32Array()]
	elif unknown_list.size() > 0 and unknown_list.size() == actual_field:
		# Every neighbouring field is a bomb
		return [PackedInt32Array(), unknown_list]
		
	if actual_field not in [1, 2] or unknown_list.size() > 3:
		return [[], []] # No info can be generated using a two cell pattern
	
	var safe_cells := PackedInt32Array()
	var bomb_cells := PackedInt32Array()
	# For every known non-bomb axis neighbour, there is a chance to learn more
	# about the grid
	for r in remaining_list:
		var r_field := grid_knowledge[r]
		var r_neighbours := _surrounding_neighbours[r]
		var r_unknown_list := PackedInt32Array()
		for n in r_neighbours:
			# Determine the actual field value
			if grid_knowledge[n] == BOMB:
				r_field -= 1
			# Collect unknown fields
			elif grid_knowledge[n] == NO_KNOWLEDGE:
				r_unknown_list.append(n)
		
		if r_field not in [1, 2] or r_unknown_list.size() > 3:
			continue
			
		if actual_field == 1 and r_field == 1:
			var safe_cell := -1
			var found_one := false
			for u in unknown_list + r_unknown_list:
				if not r_unknown_list.has(u) or not unknown_list.has(u):
					if not found_one:
						safe_cell = u
						found_one = true
					else:
						safe_cell = -1
						break
			if safe_cell != -1:
				safe_cells.append(safe_cell)
		elif actual_field == 1 and r_field == 2:
			var bomb_cell := _pattern_helper(r_unknown_list, unknown_list)
			if bomb_cell != -1:
				bomb_cells.append(bomb_cell)
		elif actual_field == 2 and r_field == 1:
			var bomb_cell := _pattern_helper(unknown_list, r_unknown_list)
			if bomb_cell != -1:
				bomb_cells.append(bomb_cell)
		
	return [safe_cells, bomb_cells]


func _pattern_helper(list1: PackedInt32Array, list2: PackedInt32Array) -> int:
	var cell := -1
	var found_one := false
	for u in list1:
		if not u in list2:
			if not found_one:
				cell = u
				found_one = true
			else:
				return -1
	return cell


## Reveals a continous area of zeros (including their border regions) and returns
## a list containing two elements:
## - a list of indices containing zeros
## - a list of new work items
func _reveal_zero_area(stard_index: int) -> Array[PackedInt32Array]:
	assert(_grid[stard_index] == 0) 
	var work_list := PackedInt32Array()
	work_list.append(stard_index)
	
	var zeros := PackedInt32Array()
	var border := PackedInt32Array()
	
	while not work_list.is_empty():
		# pop first
		var current = work_list[0] 
		work_list.remove_at(0)
		
		var neighbours := _surrounding_neighbours[current]
		for n in neighbours:
			if _grid[n] == 0:
				if n not in zeros:
					work_list.append(n)
					zeros.append(n)
			else:
				border.append(n)
	
	return [zeros, border]
