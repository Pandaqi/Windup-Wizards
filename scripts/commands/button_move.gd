class_name ButtonMove

var btn
var posA
var posB

func _init(button, a, b):
	btn = button
	posA = a
	posB = b

func execute(map):
	btn.show_reminders()
	
	map.parallel_tween.interpolate_property(btn, "position",
		posA, posB, 0.3,
		Tween.TRANS_LINEAR, Tween.EASE_OUT)
	map.parallel_tween.start()
	
	yield(map.get_tree(), "idle_frame")
	return false

func rollback(map):
	map.parallel_tween.interpolate_property(btn, "position",
		posB, posA, 1.0,
		Tween.TRANS_LINEAR, Tween.EASE_OUT)
	map.parallel_tween.start()
	
	yield(map.get_tree(), "idle_frame")
	return false
