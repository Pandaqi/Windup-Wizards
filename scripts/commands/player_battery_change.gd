class_name PlayerBatteryChange

var val

func _init(v):
	val = v

func execute(map):
	map.get_player().number.change_battery(val)
	yield(map.get_tree(), "idle_frame")
	
	return false

func rollback(map):
	map.get_player().number.change_battery(-val)
	yield(map.get_tree(), "idle_frame")
