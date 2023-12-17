class_name Attract

var e
var d : Vector2
var inv : bool
var failed : bool = false

func _init(entity, dir, invert):
	e = entity
	d = dir
	inv = invert

func execute(map):
	var other_entities = map.helpers.get_first_entities_in_dir(e.grid_pos, d)
	if other_entities.size() <= 0:
		failed = true
		yield(map.get_tree(), "idle_frame")
		return true
	
	var magnet_dir = -d
	var audio_key = "magnet_attract"
	if inv: 
		magnet_dir = d
		audio_key = "magnet_repel"
	
	GAudio.play_dynamic_sound(e, audio_key)
	
	for ent in other_entities:
		var move_cmd = PosChange.new(ent, magnet_dir, false)
		yield(map.commands.add_and_execute(move_cmd), "completed")
		if move_cmd.failed: failed = true
	
	return false

func rollback(map):
	yield(map.get_tree(), "idle_frame")
	
	if failed: return

	# NOTE: inverted as opposed to execute(), because a repelled thing will now shoot back in undo
	var audio_key = "magnet_repel"
	if inv: audio_key = "magnet_attract"
	
	GAudio.play_dynamic_sound(e, audio_key)
	
	pass # any commands spawned in execute(), will be rolled back automatically by the Command manager, should NOT do it here
