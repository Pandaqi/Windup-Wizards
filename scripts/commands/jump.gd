class_name Jump

var e
var d : Vector2
var drag : bool
var failed : bool = false

func _init(entity, dir, dr = false):
	e = entity
	d = dir
	drag = dr

func execute(map):
	var start_pos = e.grid_pos
	var target_pos = start_pos + d
	if not map.helpers.can_enter(e, target_pos):
		failed = true
		yield(map.get_tree(), "idle_frame")
		return
	
	if e.is_player(): map.helpers.check_knobs(start_pos, d)
	
	map.commands.add_and_execute(MoveTween.new(e, start_pos, target_pos, false))
	move_to_pos_in_grid(map, target_pos)
	
	var allow_dragging : bool = map.data.config.p_drag
	if allow_dragging:
		if not e.is_player() and map.player_here(start_pos):
			map.commands.add_and_execute(PosChange.new(map.get_player(), d, true))
	
	yield(get_correct_tween(map), "tween_all_completed")
	
	if not drag:
		yield(e.interactor.evaluate_current_cell(), "completed")
	
	return true

func rollback(map):
	yield(map.get_tree(), "idle_frame")
	
	if failed: return
	
	var target_pos = e.grid_pos - d
	move_to_pos_in_grid(map, target_pos)

func get_correct_tween(map):
	var tween_used = map.tween
	if drag: tween_used = map.parallel_tween
	return tween_used

func move_to_pos_in_grid(map, pos: Vector2):
	map.get_cell(e.grid_pos).entities.remove(e)
	
	e.set_grid_pos(pos)
	map.get_cell(pos).entities.add(e)
