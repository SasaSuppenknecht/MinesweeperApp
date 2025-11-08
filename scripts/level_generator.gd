extends Node

signal task_completed

const THREAD_COUNT = 1
const GENERATOR_INSTANCE = preload("res://scripts/generator_instance.gd")

var generators : Array[GENERATOR_INSTANCE] = []
var threads : Array[Thread] = []
var mutex = Mutex.new()

var result : Board

func _ready():
	generators.resize(THREAD_COUNT)
	threads.resize(THREAD_COUNT)
	for i in THREAD_COUNT:
		generators[i] = GENERATOR_INSTANCE.new()
		threads[i] = Thread.new()


func create_grid(size: int, number_of_bombs: int) -> Board:
	result = null
	# Precompute neighbours
	var neighbours : Array[PackedInt32Array] = []
	neighbours.resize(size * size)
	for i in neighbours.size():
		neighbours[i] = _get_surrounding_coordinates(i, size)
	
	for g in generators:
		g.running = true
	for i in THREAD_COUNT:
		var generator := generators[i]
		threads[i].start(generator.create_grid.bind(size, number_of_bombs, result_callback, neighbours))
	await task_completed
	for t in threads:
		t.wait_to_finish()
		
	return result


func result_callback(grid: Board):
	mutex.lock()
	if result == null:
		result = grid
		for g in generators:
			g.running = false
		task_completed.emit.call_deferred()
	mutex.unlock()


func _get_surrounding_coordinates(index: int, size: int) -> PackedInt32Array:
	var indexMinusSize := index - size
	var indexPlusSize := index + size
	var coords : Array[int]
	if (index + 1) % size == 0: # At the right edge
		coords = [
			indexMinusSize, index - 1, indexPlusSize, indexMinusSize - 1, indexPlusSize - 1,
		]
	elif index % size == 0: # At left edge
		coords = [
			indexMinusSize, index + 1, indexPlusSize, indexMinusSize + 1, indexPlusSize + 1, 
		]
	else:
		coords = [
			indexMinusSize, indexPlusSize, index - 1, index + 1,
			indexMinusSize - 1, indexPlusSize - 1, indexMinusSize + 1, indexPlusSize + 1,
		]
	return PackedInt32Array(coords.filter(func(i): return i >= 0 and i < size * size))


@warning_ignore_start("shadowed_variable")
class Board:
	extends RefCounted
	
	var grid : PackedInt32Array
	var start_field : int
	var zero_areas : Array[PackedInt32Array]
	
	func _init(grid, start_field, zero_areas):
		self.grid = grid
		self.start_field = start_field
		self.zero_areas = zero_areas
