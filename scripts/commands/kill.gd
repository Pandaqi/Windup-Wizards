class_name Kill

var e
var instant : bool = false

func _init(entity, i = false):
	e = entity
	instant = i

func execute(map):
	e.die(instant)
	yield(map.tween, "tween_all_completed")

	return false

func rollback(map):
	e.revive(instant)
	
	yield(map.tween, "tween_all_completed")
	return false
