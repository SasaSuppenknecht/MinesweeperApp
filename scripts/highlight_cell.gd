extends Cell

func reveal_cell(recurse: bool = true):
	$ColorRect2.color = GRAY
	super.reveal_cell(recurse)
