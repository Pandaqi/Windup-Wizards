class_name PickupKnob

var cell

func _init(c):
	cell = c

func execute(map):
	map.get_player().knob_holder.add()
	cell.knob.hide_knob()
	
	GAudio.play_dynamic_sound(cell, "loose_knob")
	
	yield(map.tween, "tween_all_completed")
	return false

func rollback(map):
	cell.knob.show_knob()
	map.get_player().knob_holder.remove()
	
	GAudio.play_dynamic_sound(cell, "loose_knob")
	
	yield(map.tween, "tween_all_completed")
