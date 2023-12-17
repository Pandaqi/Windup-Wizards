class_name PosChange

var e
var d : Vector2
var drag : bool = false
var failed : bool = false

func _init(entity, dir, dr = false):
	e = entity
	d = dir
	drag = dr

func is_valid(map):
	return map.helpers.entity_can_move_in_dir(e, d)

func on_execute_invalid(map):
	failed = true

	# play a bouncy tween to indicate we stopped
	map.tween.interpolate_property(e, "scale",
		e.scale*1.5, e.scale, GDict.cfg.tweens.stop_dur,
		Tween.TRANS_LINEAR, Tween.EASE_OUT)
	map.tween.start()
	
	if map.data.config.stop_after_enc:
		map.feedback.create_from_3d(e.translation, "Movement blocked!")
	
	yield(map.tween, "tween_all_completed")

func execute(map):
	var start_pos = e.grid_pos
	var end_pos = start_pos + d

	move_in_dir(map, d)
	map.commands.add_and_execute(MoveTween.new(e, start_pos, end_pos, drag))

	print("SUCCESFUL MOVE")
	
	if not drag:
		GAudio.play_dynamic_sound(e, "player_move")
	
	if e.is_player(): map.helpers.check_knobs(start_pos, d)
	
	# The reason we can drag + move simultaneously now,
	# Is because I don't call this command in a yield(<>, "completed")
	var allow_dragging : bool = map.data.config.p_drag
	if allow_dragging:
		if not e.is_player() and map.player_here(start_pos):
			map.commands.add_and_execute(get_script().new(map.get_player(), d, true))
	
	yield(get_correct_tween(map), "tween_all_completed")

#	TO DO/DEBUGGING: turned this off because it meant the player drag arrived AFTER the entity move, which was bad for evaluation
#	If this breaks earlier levels, find another way
#	if drag and map.tween.is_active():
#		yield(map.tween, "tween_all_completed")
	
	print("WAITED FOR TWEEN COMPLETE")
	
	print("DRAG?")
	print(drag)
	
	# interacting with something might make us stop moving
	var stop_moving = false
	if not drag:
		print("SHOULD CALL EVALUATION")
		stop_moving = yield(e.interactor.evaluate_current_cell(), "completed")
	
	print("GOT HERO")
	
	# if not, check if general rules make us stop moving
	if not stop_moving:
		stop_moving = map.helpers.must_stop_moving(e, d) or (not map.helpers.entity_can_move_in_dir(e,d))
	
	if !map.data.config.stop_after_enc:
		stop_moving = false
	
	return stop_moving

func rollback(map):
	if failed: 
		yield(map.get_tree(), "idle_frame")
		return
	
	move_in_dir(map, -d)
	
	print("ROLLING BACK MOVE")
	print("Is player?")
	print(e.is_player())
	print("Dir?")
	print(-d)
	
	var tw = get_correct_tween(map)
	var did_something = false
	if tw.is_active():
		did_something = true
		yield(tw, "tween_all_completed")
	
	print("MOVE ROLL BACK DONE")

	if not did_something:
		yield(map.get_tree(), "idle_frame")

func move_in_dir(map, dir: Vector2):
	var grid_pos = e.grid_pos
	var new_pos = grid_pos + dir
	
	if e.is_player():
		map.highlight_player_cell(new_pos)
	
	e.last_move_dir = map.helpers.get_dir_from_vec(dir)
	
	map.get_cell(grid_pos).entities.remove(e)
	map.get_cell(new_pos).entities.add(e)
	e.set_grid_pos(new_pos)

func get_correct_tween(map):
	var tween_used = map.tween
	if drag: tween_used = map.parallel_tween
	return tween_used
