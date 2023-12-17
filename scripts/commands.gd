extends Node

var commands : Array = []
var busy : bool = false

onready var map = get_node("/root/Main/Map")
onready var tween : Tween = get_node("/root/Main/Tween")
onready var parallel_tween : Tween = get_node("/root/Main/ParallelTween")

onready var feedback = get_node("/root/Main/Feedback")

func open_new_move():
	commands.append([])
	busy = true

func close_move():
	print("Move closed")
	busy = false

func add_and_execute(cmd):
	var valid : bool = true
	if cmd.has_method("is_valid"): valid = cmd.is_valid(map)
	if not valid:
		yield(cmd.on_execute_invalid(map), "completed")
		return true
	
	commands[commands.size() - 1].append(cmd)
	
	var must_stop = yield(cmd.execute(map), "completed")
	return must_stop

func pop_and_rollback():
	if commands.size() <= 0:
		feedback.create_at_player("Nothing to undo!")
		yield(get_tree(), "idle_frame")
		return false
	
	G.undo_mode = true
	
	busy = true
	tween.playback_speed = GDict.cfg.tweens.undo_speedup
	parallel_tween.playback_speed = tween.playback_speed
	
	var last_cmds = commands.pop_back()
	for i in range(last_cmds.size()-1,-1,-1):
		var cmd = last_cmds[i]
		print(i)
		print(cmd)
		yield(cmd.rollback(map), "completed")
		
	
	print("WENT THROUGH ALL COMMANDS")
	
	if tween.is_active():
		yield(tween, "tween_all_completed")
	
	print("GOT HERE")
	
	if parallel_tween.is_active():
		yield(parallel_tween, "tween_all_completed")
	
	busy = false
	tween.playback_speed = 1.0
	parallel_tween.playback_speed = 1.0
	
	G.undo_mode = false
	
	return true

func is_busy():
	return busy
