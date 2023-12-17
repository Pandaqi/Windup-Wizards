extends Spatial

var type : String
var bad : bool
var model_scene
var models = []

var action_icon = null
var front_model = null
var stack_extreme

var is_highlighted : bool = false

onready var body = get_parent()

var good_wizard_scene = preload("res://scenes/wizards/wizard_good.tscn")
var bad_wizard_scene = preload("res://scenes/wizards/wizard_bad.tscn")
var menu_wizard_scene = preload("res://scenes/wizards/wizard_menu.tscn")
var world_wizard_scene = preload("res://scenes/wizards/wizard_world.tscn")

var default_mat = preload("res://materials/Material.material")
var grayed_mat = preload("res://materials/MaterialGrayed.material")

var extruded_num_mat = preload("res://materials/extruded_number.tres")
var extruded_num_grayed_mat = preload("res://materials/extruded_number_grayed.tres")

onready var player_gust = preload("res://scenes/player_gust.tscn")

onready var action_hint = $ActionHint
onready var action_hint_sprite = $ActionHint/Sprite3D

onready var tween = $Tween
onready var main_tween = get_node("/root/Main/Tween")

const BUNNY_STACK_OFFSET = Vector3.UP*1.5
const HAT_STACK_OFFSET = Vector3.UP*1.0
const VISUAL_SCALE : float = 0.75
const ACTION_ICON_OFFSET : float = 0.05

func _ready():
	set_scale(Vector3.ONE*VISUAL_SCALE)

func set_type(tp : String):
	type = tp

	if type == "player":
		load_gust_particles()
	
	add_action_icon()
	action_hint.set_type(type)

func add_action_icon():
	if not GDict.action_icons.has(type): return

	action_icon = GDict.action_icons[type].instance()
	add_child(action_icon)

func load_gust_particles():
	var g = player_gust.instance()
	add_child(g)
	g.set_translation(Vector3.UP)

func destroy_existing_models():
	for i in range(models.size()):
		models[i].queue_free()
	models = []

func load_model():
	if type == "player": return
	
	if bad:
		model_scene = bad_wizard_scene
	else:
		if type == "menu":
			model_scene = menu_wizard_scene
		elif type == "world":
			model_scene = world_wizard_scene
		else:
			model_scene = good_wizard_scene
	
	var models_to_load = GDict.cfg.max_number
	if type == "menu" or type == "world": models_to_load = 1
	
	models = []
	for _i in range(models_to_load):
		var m = model_scene.instance()
		m.set_visible(false)
		add_child(m)
		models.append(m)
	
	update_models(body.number.count())

func check_if_unlocked(level):
	if type != "menu": return
	
	if not GSave.is_level_playable_by_index(level):
		apply_material_to_all_children(self, [grayed_mat, extruded_num_grayed_mat])
	
	if GSave.is_level_unlocked_by_index(level):
		front_model.queue_free()
		front_model = GDict.action_icons.success.instance()
		add_child(front_model)
		position_in_front(front_model)

func update_models(cur_number, instant = false):
	var extreme = abs(cur_number)
	
	# toggle highlight between 0 (no number) and 1 (a number, can be activted)
	set_highlight((extreme != 0))
	
	if extreme == 0: extreme = 1
	stack_extreme = extreme
	
	print("UPDATE HERO 1")
	
	# update stack (remove/show models at top to fit number)
	for i in range(models.size()):
		var m = models[i]
		var should_appear = (i < extreme)
		var already_appeared = m.is_visible()
		
		if should_appear and not already_appeared:
			appear_model(true, m, i, instant)
		elif not should_appear and already_appeared:
			appear_model(false, m, i, instant)
	
	print("UPDATE HERO 2")
	
	# put action icon on top
	if action_icon:
		var icon_move_dur = GDict.cfg.tweens.model_appear_dur
		var new_icon_trans = get_top_height(true) 
		main_tween.interpolate_property(action_icon, "translation",
			action_icon.translation, new_icon_trans, 0.5*icon_move_dur,
			Tween.TRANS_LINEAR, Tween.EASE_OUT)
		main_tween.start()
	
	print("UPDATE HERO 3")
	
	# reverse if necessary
	var invert = (cur_number < 0)
	var is_already_inverted = (self.scale.x < 0)
	
	action_hint.set_invert(invert)
	
	if invert != is_already_inverted:
		var start_scale = Vector3(1,1,1)*VISUAL_SCALE
		var end_scale = Vector3(-1,1,1)*VISUAL_SCALE
		var dur = GDict.cfg.tweens.model_invert_dur
		
		if not invert:
			start_scale = Vector3(-1,1,1)*VISUAL_SCALE
			end_scale = Vector3(1,1,1)*VISUAL_SCALE
		
		main_tween.interpolate_property(self, "scale",
			start_scale, end_scale, dur,
			Tween.TRANS_LINEAR, Tween.EASE_OUT)
		main_tween.start()
	
	print("UPDATE HERO 4")

func appear_model(yes: bool, model, index, instant: bool = false):
	var dur = GDict.cfg.tweens.model_appear_dur
	if instant: dur = 0.0001
	
	if yes:
		model.set_visible(true)
	else:
		tween.interpolate_property(model, "rotation",
			0, 0, max(dur-0.02, 0.0001),
			Tween.TRANS_LINEAR, Tween.EASE_OUT)
		tween.start()
	
	var start_scale = Vector3.ZERO
	var end_scale = Vector3.ONE*(1.0 + 0.01*index) # each model is slightly bigger to prevent Z-fighting in the stack
	var middle_scale = (start_scale + end_scale) * 0.5
	var middle_scale_flat = end_scale * Vector3(1.25, 0.5, 1.25)
	var middle_scale_tall = end_scale * Vector3(0.5, 1.25, 0.5)
	
	if not yes:
		var temp = end_scale
		end_scale = start_scale
		start_scale = temp
	
	model.set_scale(middle_scale)
	main_tween.interpolate_property(model, "scale",
		middle_scale, middle_scale_flat, 0.2*dur,
		Tween.TRANS_LINEAR, Tween.EASE_OUT,
		0.4*dur)
	main_tween.interpolate_property(model, "scale",
		middle_scale_flat, middle_scale_tall, 0.2*dur,
		Tween.TRANS_LINEAR, Tween.EASE_OUT,
		0.6*dur)
	main_tween.interpolate_property(model, "scale",
		middle_scale_tall, end_scale, 0.2*dur,
		Tween.TRANS_LINEAR, Tween.EASE_OUT,
		0.8*dur)
	
	var stack_offset = BUNNY_STACK_OFFSET
	if not bad: stack_offset = HAT_STACK_OFFSET
	
	var start_pos = stack_offset*(index - 1)
	var middle_pos = stack_offset*(index + 2)
	var end_pos = stack_offset*index
	if not yes:
		var temp = end_pos
		end_pos = start_pos
		start_pos = temp
	
	model.set_translation(start_pos)
	main_tween.interpolate_property(model, "translation",
		start_pos, middle_pos, 0.5*dur,
		Tween.TRANS_CUBIC, Tween.EASE_OUT)
	main_tween.interpolate_property(model, "translation",
		middle_pos, end_pos, 0.5*dur,
		Tween.TRANS_CUBIC, Tween.EASE_IN,
		0.5*dur)

	main_tween.start()

func get_top_height(include_icon_offset = false, low_jump_allowed = false):
	var stack_offset = BUNNY_STACK_OFFSET
	if not bad: stack_offset = HAT_STACK_OFFSET
	
	if low_jump_allowed and body.number.count() == 0: return Vector3.ZERO
	
	# first one is always full length of course
	# the others depend on stack height
	# then some extra offset for the action icon
	var val = Vector3.UP*2*VISUAL_SCALE + (stack_extreme-1)*stack_offset
	if include_icon_offset: val += Vector3.UP*ACTION_ICON_OFFSET
	return val

func set_highlight(yes: bool):
	if models.size() <= 1: return
	if yes != is_highlighted and yes:
		pass
		
		# TO DO: decided this was too messy, combined with all other sounds => Also, there was no "deactivate" to reverse it
		# GAudio.play_dynamic_sound(body, "activate")
	is_highlighted = yes
	
	var materials = [default_mat, extruded_num_mat]
	if not yes: materials = [grayed_mat, extruded_num_grayed_mat]
	
	apply_material_to_all_children(models[0], materials)

func apply_material_to_all_children(node, materials):
	for N in node.get_children():
		if N.get_child_count() > 0:
			apply_material_to_all_children(N, materials)
		else:
			if N is MeshInstance:
				if N.get_parent().is_in_group("ExtrudedNumbers"):
					N.material_override = materials[1]
				else:
					N.material_override = materials[0]

func on_team_updated(new_val : bool):
	bad = new_val
	destroy_existing_models()
	load_model()

func position_in_front(m):
	m.set_translation(Vector3.BACK*0.95 + Vector3.UP*0.5)
	m.set_scale(Vector3.ONE*2)
	m.rotate_x(0.5*PI)

func show_extruded_number(index):
	if type == "world": return
	
	# indices count from 0 (as usual in arrays)
	# but to the users, we want to start counting from 1 (as they'd expect)
	front_model = GDict.extruded_numbers[index + 1].instance()
	front_model.add_to_group("ExtrudedNumbers")
	position_in_front(front_model)
	add_child(front_model)

func load_tiny_level(index):
	if type == "world": return
	
	var data = GjsonLoader.get_custom_level(index)
	var cont = Spatial.new()
	var center_offset = -0.5*Vector3(data.width*2, 0, data.height*2)
	
	for x in range(data.width):
		for y in range(data.height):
			var idx = x + y*data.width
			var cell = data.cells[idx]
			if cell == -1: continue
			
			var cell_model = GDict.cube_models[cell].instance()
			var pos = Vector3(x+0.5,0,y+0.5)*2 + Vector3.UP + center_offset
			cell_model.set_translation(pos + 2*Vector3.DOWN)
			cont.add_child(cell_model)
			
			var delay = randf()*1.0
			tween.interpolate_property(cell_model, "translation",
				pos + 2*Vector3.DOWN, pos, 1.0,
				Tween.TRANS_ELASTIC, Tween.EASE_OUT,
				delay
				)
			
			for e in data.entities[idx]:
				var entity_model
				if e.kind == "player": continue
				if e.has('bad') and e.bad:
					entity_model = preload("res://scenes/wizards/bunny_simplified.tscn")
				else:
					entity_model = preload("res://scenes/wizards/wizard_good.tscn")
				
				var num_models = 1
				if e.has('number'):
					num_models = max(abs(e.number), 1)
				
				for i in range(num_models):
					var entity_model_instance = entity_model.instance()
					var e_pos = pos + Vector3.UP + i*2*Vector3.UP
					entity_model_instance.set_translation(e_pos + 2*Vector3.DOWN)
					cont.add_child(entity_model_instance)
					
					entity_model_instance.rotation = Vector3.UP * -e.rot*0.5*PI
					
					tween.interpolate_property(entity_model_instance, "translation",
						entity_model_instance.translation, e_pos, 1.0,
						Tween.TRANS_ELASTIC, Tween.EASE_OUT,
						delay + 1.0
					)

	add_child(cont)

	cont.scale = Vector3.ONE*0.15
	cont.translation = Vector3.UP*2
	
	tween.start()

func _on_Tween_tween_completed(object, key):
	# this is a "fake tween" on the rotation (0->0) so we know when to hide the model
	if object in models and key == ":rotation":
		print("MAKING OBJECT INVISIBLE AGAIN")
		object.set_visible(false)
