class_name Stack

var giver
var receiver

func _init(g,r):
	giver = g
	receiver = r

func execute(map):
	var num_points_giver = giver.number.count()
	
	# THIS IS NOT STRICTLY NECESSARY
	# the giver is drained completely
	# yield(map.commands.add_and_execute(PointChange.new(giver, -num_points_giver)), "completed")
	
	# leading to their death as well
	# THIS IS NECESSARY (otherwise we get two separate entities on the same cell, not allowed)
	# Second parameter (true) = instant, no tween delay
	yield(map.commands.add_and_execute(Kill.new(giver, true)), "completed")
	
	print("STACK => Kill done")
	
	# the receiver gets those points
	# but ONLY to extend their current direction, not in the mathematical sense
	var num_points_receiver = receiver.number.count()
	var dir = 1 if num_points_receiver >= 0 else -1
	var points_for_receiver = abs(num_points_giver)*dir
	yield(map.commands.add_and_execute(PointChange.new(receiver, points_for_receiver, true)), "completed")

	return true

func rollback(map):
	# nothing: only adds commands
	yield(map.get_tree(), "idle_frame")
	return false
