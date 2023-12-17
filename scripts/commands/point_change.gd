class_name PointChange

var e
var c
var instant : bool = false

func _init(entity, change, i = false):
	e = entity
	c = change
	instant = i

func execute(map):
	if e.dead: 
		yield(map.get_tree(), "idle_frame")
		return false
	
	print("PointChange started")
	
	# NOTE/CRUCIAL: If the number change is from 0 to 1, no tween is created (only material on model is changed)
	# That's why we need to check it here
	# TO DO: Better solution is probably to add a tween even then
	e.number.change(c, instant)
	if map.tween.is_active():
		yield(map.tween, "tween_all_completed")
	else:
		yield(map.get_tree(), "idle_frame")
	
	print("PointChange ended")
	
	return false

func rollback(map):
	if e.dead: 
		yield(map.get_tree(), "idle_frame")
		return
	
	e.number.change(-c, instant)
	if map.tween.is_active():
		yield(map.tween, "tween_all_completed")
	else:
		yield(map.get_tree(), "idle_frame")
	
	return false
