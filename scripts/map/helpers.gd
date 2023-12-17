extends Node

onready var map = get_parent()

func get_real_pos(grid_pos: Vector2, centred:bool = true) -> Vector3:
	if centred: grid_pos += Vector2(0.5, 0.5)
	return Vector3(grid_pos.x, 0, grid_pos.y) / map.config.tile_size

func get_grid_pos(real_pos: Vector3) -> Vector2:
	var x = floor(real_pos.x / map.config.tile_size)
	var y = floor(real_pos.z / map.config.tile_size)
	return Vector2(x,y)

func get_index_from_pos(grid_pos : Vector2) -> int:
	return grid_pos.x + grid_pos.y*map.data.width

func get_pos_from_index(index: int) -> Vector2:
	return Vector2(index % int(map.data.width), floor(index / map.data.width))

func get_dir_from_vec(vec: Vector2) -> int:
	if vec.x > 0.5: return 0
	elif vec.x < -0.5: return 2
	elif vec.y > 0.5: return 1
	elif vec.y < -0.5: return 3
	return -1

func get_vec_from_dir(dir: int) -> Vector2:
	if dir == 0: return Vector2.RIGHT
	elif dir == 1: return Vector2.DOWN
	elif dir == 2: return Vector2.LEFT
	return Vector2.UP

func out_of_bounds(pos: Vector2) -> bool:
	return pos.x < 0 or pos.y < 0 or pos.x >= map.data.width or pos.y >= map.data.height

func can_enter(entity, pos: Vector2) -> bool:
	var cell = map.get_cell(pos)
	if not cell: return false
	if not cell.active: return false
	if not cell.entities.allow_entry_to(entity): return false
	return true

func entity_can_move_in_dir(ent, dir: Vector2) -> bool:
	var cur_pos = ent.grid_pos
	var new_pos = cur_pos + dir
	
	print("ENTITY TRIES TO MOVE IN DIR")
	print(dir)
	print(cur_pos)
	print(new_pos)
	
	if out_of_bounds(new_pos): return false
	if not can_enter(ent, new_pos): return false
	return true

func get_first_entities_in_dir(pos: Vector2, dir: Vector2):
	while true:
		pos += dir
		if out_of_bounds(pos): break
		
		var cell = map.get_cell(pos)
		if not cell.entities.has_some(): continue
		
		return cell.entities.get_them()
	
	return []

func get_knob_at(move_cell_pos, cell_pos, change_dir) -> Dictionary:
	var cell = map.get_cell(cell_pos)
	var obj = {
		'failed': true,
		'entity': null,
		'knob_index': -1,
	}

	if not cell or not cell.active: return obj
	if not cell.entities.has_some(): return obj
	
	var dir = get_dir_from_vec(move_cell_pos - cell_pos)
	for e in cell.entities.get_them():
		obj.entity = e
		obj.knob_index = e.knobs.get_in_dir(dir)

		if obj.knob_index < 0: continue
		
		obj.failed = false
		break
	
	if obj.entity and obj.entity.number.at_max_capacity() and sign(change_dir) == sign(obj.entity.number.count()):
		obj.failed = true
	
	return obj

func must_stop_moving(e, _dir) -> bool:
	print("MUST STOP MOVING?")
	
	var has_blocking_entity = false
	var cur_cell = map.get_cell(e.grid_pos)
	for entity in cur_cell.entities.get_excluding([e]):
		if e.is_player():
			if entity.is_passthrough() and entity.number.is_positively_wound(): 
				GAudio.play_dynamic_sound(e, "ghost")
				continue
		if entity.is_player(): continue
		has_blocking_entity = true
		break
	
	if not e.is_player():
		if map.get_cell(e.grid_pos).is_hole(): return true
	
	if e.is_player():
		if map.get_cell(e.grid_pos).is_pause(): return true
	
	print(has_blocking_entity)
	
	return has_blocking_entity


# TO DO: Might be some issues with rounding along the way => (-0,-0) in vector,
# how to combat that efficiently throughout the whole grid system?
func check_knobs(start_pos, dir):
	dir = dir.normalized() 
	
	var side_right_pos = (start_pos + dir.rotated(0.5*PI)).round()
	var side_left_pos = (start_pos + dir.rotated(-0.5*PI)).round()
	
	var knob_right = get_knob_at(start_pos, side_right_pos, 1)
	var knob_left = get_knob_at(start_pos, side_left_pos, -1)

	if not knob_right.failed:
		map.commands.add_and_execute(TurnKnob.new(knob_right.entity, knob_right.knob_index, 1))
		map.commands.add_and_execute(PointChange.new(knob_right.entity, 1))
	
	var reverse_winding_allowed = map.data.config.rev_wind
	var change_dir = -1
	if not reverse_winding_allowed: change_dir = 1
	
	print("KNOB LEFT?")
	print(knob_left)
	
	if not knob_left.failed:
		map.commands.add_and_execute(TurnKnob.new(knob_left.entity, knob_left.knob_index, change_dir))
		map.commands.add_and_execute(PointChange.new(knob_left.entity, change_dir))
