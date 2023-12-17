class_name PointTransfer

var e1
var e2

func _init(entity, other_entity):
	e1 = entity
	e2 = other_entity

func execute(map):
	var num = e1.number.count()
	e1.number.change(-num)
	e2.number.change(num)
	
	yield(map.tween, "tween_all_completed")
	
	# after the transfer, any execution should always stop, as there's nothing more to do
	return true

func rollback(map):
	var num = e2.number.count()
	e1.number.change(num)
	e2.number.change(-num)
	
	yield(map.tween, "tween_all_completed")
	return true
