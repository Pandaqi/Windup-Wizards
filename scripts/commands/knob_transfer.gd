class_name KnobTransfer

var e
var d

func _init(entity, dir):
	e = entity
	d = dir

func execute(map):
	e.knobs.place_knob_at_global_dir(d)
	map.get_player().knob_holder.remove()
	
	GAudio.play_dynamic_sound(e, "loose_knob")
	
	yield(map.tween, "tween_all_completed")
	return true

func rollback(map):
	map.get_player().knob_holder.add()
	e.knobs.remove_knob_at_global_dir(d)
	
	GAudio.play_dynamic_sound(e, "loose_knob")
	
	yield(map.tween, "tween_all_completed")
