class_name SwitchTeam

var e

func _init(entity):
	e = entity

func execute(map):
	print("SWITCH TEAM CALLED")
	
	e.switch_team()

	# NOTE: switching team means models are removed and re-added
	# which automatically creates a tween for us!
	if map.tween.is_active():
		yield(map.tween, "tween_all_completed")
	else:
		yield(map.get_tree(), "idle_frame")
	return false

func rollback(map):
	print("SWITCH ROLLBACK STARTED")
	
	e.switch_team()
	
	if map.tween.is_active():
		yield(map.tween, "tween_all_completed")
	else:
		yield(map.get_tree(), "idle_frame")
	
	print("SWITCH ROLLBACK COMPLETE")
