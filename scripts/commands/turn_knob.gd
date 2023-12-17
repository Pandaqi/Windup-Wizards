class_name TurnKnob

var e
var k : int
var d : int

func _init(entity, knob, dir):
	e = entity
	k = knob
	d = dir

func execute(map):
	e.knobs.turn_knob(k, d)
	
	GAudio.play_dynamic_sound(e, "knob_turn")
	
	yield(map.tween, "tween_all_completed")
	return false

func rollback(map):
	e.knobs.turn_knob(k, -d)
	
	GAudio.play_dynamic_sound(e, "knob_turn")
	
	yield(map.tween, "tween_all_completed")
	return false
