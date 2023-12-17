extends Spatial

var grid_pos : Vector2
var rot : int
var visual_rot : int
var type : String
var bad : bool = false
var level : int = -1
var support : bool = false

var dead : bool = false

var scale_before_death : Vector3

var being_dragged : bool = false
var last_move_dir : int = -1

onready var map = get_node("/root/Main/Map")
onready var tween = get_node("/root/Main/Tween")
onready var feedback = get_node("/root/Main/Feedback")

onready var knobs = $Knobs
onready var knob_holder = $KnobHolder
onready var number = $Number
onready var interactor = $Interactor
onready var executor = $Executor
onready var visuals = $Visuals

func activate(data):
	if not data.has('rot'): data.rot = 0
	if not data.has('kind'): data.kind = "move"
	if not data.has('bad'): data.bad = false
	if not data.has('number'): data.number = 0
	if not data.has('support'): data.support = false
	
	set_rot(data.rot)
	set_type(data.kind)
	set_team(data.bad) # NOTE: set_team must be the last of all them

	executor.activate(data)
	if not executor.support:
		$Visuals/Support.queue_free()
	
	knobs.activate(data)
	number.activate(data)
	
	if is_player(): map.highlight_player_cell(grid_pos)
	if data.has('level'): 
		level = data.level
		visuals.load_tiny_level(level)
		visuals.show_extruded_number(level)
		visuals.check_if_unlocked(level)

func set_grid_pos(p:Vector2):
	grid_pos = p

func update_rot(dir:int):
	set_rot(visual_rot + dir)

func set_rot(val:int):
	visual_rot = val
	rot = (val + 4) % 4
	
	var old_rot = self.rotation
	var new_rot = old_rot
	new_rot.y = -visual_rot*0.5*PI
	
	tween.interpolate_property(self, "rotation",
		old_rot, new_rot, GDict.cfg.tweens.rot_dur,
		Tween.TRANS_CUBIC, Tween.EASE_OUT)
	tween.start()

func set_type(tp : String):
	type = tp
	
	visuals.set_type(tp)

func type_is(tp : String):
	return (type == tp)

func set_team(new_val: bool):
	bad = new_val
	
	visuals.on_team_updated(bad)

func switch_team():
	bad = not bad
	GAudio.play_dynamic_sound(self, "convert")
	
	visuals.on_team_updated(bad)

func is_player():
	return type == "player"

func is_passthrough():
	return type == "passthrough"

func get_current_cell():
	return map.get_cell(grid_pos)

func start_drag():
	being_dragged = true

func end_drag():
	being_dragged = false

func is_dead():
	return dead

func die(instant = false):
	dead = true
	
	if not instant:
		feedback.create_from_3d(translation, "Disappear!")
		GAudio.play_dynamic_sound(self, "die")
		
	scale_before_death = self.scale
	
	# shorten duration if we're under a hat
	# which is the case when our current scale is already smaller than 1
	var dur = GDict.cfg.tweens.die_dur
	if scale_before_death.y < 0.99: dur *= 0.25
	if instant: dur = 0.0001
	
	tween.interpolate_property(self, "scale",
		self.scale*1.3, Vector3.ZERO, dur,
		Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	tween.start()
	
	number.change_visibility(false, instant)
	
	get_current_cell().entities.remove(self)

func revive(instant = false):
	dead = false
	
	if not instant:
		feedback.create_from_3d(translation, "Reappear!")
		GAudio.play_dynamic_sound(self, "revive")
		
	var dur = GDict.cfg.tweens.die_dur
	if scale_before_death.y < 0.99: dur *= 0.25
	if instant: dur = 0.0001
	
	tween.interpolate_property(self, "scale",
		Vector3.ZERO, scale_before_death, dur,
		Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	tween.start()
	
	number.change_visibility(true, instant)
	
	get_current_cell().entities.add(self)
