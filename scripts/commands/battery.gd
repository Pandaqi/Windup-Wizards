class_name Battery

var e
var o : bool
var o_num : int
var inv : bool

func _init(entity, override, override_num):
	e = entity
	o = override
	o_num = override_num

func execute(map):
	var num = e.number.count()
	if o: num = o_num
	
	var dir = sign(num)
	
	# if not called with override, WE are the battery
	# so transfer our points to the player
	if not o:
		yield(map.commands.add_and_execute(PlayerBatteryChange.new(dir)), "completed")
	
	# if we're called with an override, this means a SUPPORT battery called us
	# so their points are simply added to us
	else:
		map.commands.add_and_execute(TurnKnob.new(e, -1, dir))
		yield(map.commands.add_and_execute(PointChange.new(e, dir, false)), "completed")
	
	return false

func rollback(map):
	# only commands added, so do nothing here
	yield(map.get_tree(), "idle_frame")
