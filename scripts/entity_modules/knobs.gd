extends Spatial

var knobs : Array
var knob_nodes : Array = [null, null, null, null]
var knob_scene = preload("res://scenes/knob.tscn")

onready var main_node = get_node("/root/Main")
onready var tween = get_node("/root/Main/Tween")
onready var body = get_parent()
onready var fake_tween = $FakeTween

var default_mat = preload("res://materials/Material.material")
var invert_mat = preload("res://materials/knob_invert.res")
var grayed_mat = preload("res://materials/MaterialGrayed.material")

onready var timer = $Timer

func activate(data):
	knobs = [false, false, false, false]
	
	if not data.has('knobs'): return
	if data.knobs.size() <= 0: return
	if data.knobs.size() < 4: data.knobs.resize(4)

	for i in range(4):
		if not data.knobs[i]: continue
		
		place_knob(i)

func place_knob(index : int):
	knobs[index] = true
	
	var rot = index*0.5*PI
	var knob_stick_out_ratio = 0.75
	if body.type == "menu" or body.type == "world":
		knob_stick_out_ratio = 1.25
	
	var offset_length = 0.5*(1.0 / GDict.grid_config.tile_size) * knob_stick_out_ratio
	var offset = Vector3(cos(rot), 0, sin(rot))*offset_length
	offset += 0.5*Vector3.UP
	
	var k = knob_scene.instance()
	k.rotate_y(-rot)
	add_child(k)
	
	knob_nodes[index] = k
	
	tween.interpolate_property(k, "translation",
		Vector3.ZERO, offset, GDict.cfg.tweens.knob_add,
		Tween.TRANS_BOUNCE, Tween.EASE_OUT)
	tween.start()

func place_knob_at_global_dir(index : int):
	place_knob(make_dir_global(index))
	
	# TO DO: Wasteful, as we only need to update the material on that single knob
	update_knob_materials(body.number.count())

func remove_knob(index: int):
	var k = knob_nodes[index]
	var dur = GDict.cfg.tweens.knob_add
	
	knobs[index] = false
	knob_nodes[index] = null
	
	tween.interpolate_property(k, "translation",
		k.translation, Vector3.ZERO, dur,
		Tween.TRANS_BOUNCE, Tween.EASE_OUT)
	tween.start()
	
	fake_tween.interpolate_property(k, "rotation",
		k.rotation, k.rotation, dur*0.9,
		Tween.TRANS_LINEAR, Tween.EASE_OUT)
	fake_tween.start()

func remove_knob_at_global_dir(index : int):
	remove_knob(make_dir_global(index))

func turn_knob(index : int, dir : int):
	var knobs_to_rotate = []
	if index == -1:
		knobs_to_rotate = knob_nodes
	else:
		knobs_to_rotate = [knob_nodes[index]]
	
	for k in knobs_to_rotate:
		if not k: continue
	
		var new_rotation = PI*dir
		tween.interpolate_property(k.get_node("KnobModel"), "rotation",
			Vector3.ZERO, Vector3.RIGHT*new_rotation, GDict.cfg.tweens.knob_rot_dur,
			Tween.TRANS_LINEAR, Tween.EASE_OUT)
		tween.start()
	
	timer.wait_time = GDict.cfg.tweens.knob_rot_dur + 0.1 # some offset for niceness
	timer.start()

# NOTE: THis dir is the GLOBAL dir (0 = right, 1 = down, etc.)
# In the function itself, we shift it to take the body rotation into account
func get_in_dir(dir: int):
	if not knobs[make_dir_global(dir)]: return - 1
	return make_dir_global(dir)

func make_dir_global(dir: int):
	return (dir + 4 - body.rot) % 4

func has_in_dir(dir: int):
	return knobs[make_dir_global(dir)]

func has_some():
	for i in range(4):
		if knobs[i]: return true
	return false

# Called when rotating a knob is DONE
# (Don't go via tweens, as those are handled by do/undo and it'd just be a mess for such a tiny thing)
func _on_Timer_timeout():
	# these load a LEVEL
	if body.type == "menu": 
		GjsonLoader.set_level_by_index(body.level)
		G.save_player_pos(main_node.get_player().grid_pos)
		G.goto_level()
	
	# these load the NEXT/PREVIOUS world
	elif body.type == "world":
		GjsonLoader.set_world_by_index(body.level)
		G.save_player_pos(Vector2.ZERO)
		G.goto_world()

func update_knob_materials(val):
	var invert = true if (val < 0) else false
	var mat = default_mat
	if invert: mat = invert_mat
	if val == 0: mat = grayed_mat
	
	for k in knob_nodes:
		if not k: continue
		k.get_node("KnobModel").material_override = mat

func _on_FakeTween_tween_completed(object, key):
	if key == ":rotation": object.queue_free()
