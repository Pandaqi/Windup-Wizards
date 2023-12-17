class_name Rotate

var e
var turn_dir : int

func _init(entity, d:int):
	e = entity
	turn_dir = d

func execute(map):
	e.update_rot(turn_dir)
	
	GAudio.play_dynamic_sound(e, "rotate")
	
	yield(map.tween, "tween_all_completed")
	return false

func rollback(map):
	e.update_rot(-turn_dir)
	
	GAudio.play_dynamic_sound(e, "rotate")
	
	yield(map.tween, "tween_all_completed")
	return false
