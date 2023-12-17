class_name NumberChange

# TO DO: this one does nothing now and is completely wrong

var e
var k : int
var d : int

func _init(entity, knob, dir):
	e = entity
	k = knob
	d = dir

func execute(map):
	e.knobs.turn_knob(k, d)

func rollback(map):
	e.knobs.turn_knob(k, -d)
