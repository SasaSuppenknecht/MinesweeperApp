extends Label


func _ready():
	EventBus.flag_placed.connect(decrement)
	EventBus.flag_removed.connect(increment)


var _number_of_bombs := 0 : 
	set(value):
		_number_of_bombs = value
		text = "%03d" % value


func decrement():
	_number_of_bombs -= 1
	

func increment():
	_number_of_bombs += 1
	
	
func set_counter(count: int):
	_number_of_bombs = count
