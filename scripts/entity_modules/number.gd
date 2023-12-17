extends Node2D

var val : int = 0
var active : bool = true

onready var label = $Label
onready var body = get_parent()

onready var ingame_ui = get_node("/root/Main/IngameUI")
onready var UI = get_node("/root/Main/UI")
onready var cam = get_node("/root/Main/Camera")

onready var map = get_node("/root/Main/Map")
onready var feedback = get_node("/root/Main/Feedback")

func activate(data):
	body.remove_child(self)
	ingame_ui.add_child(self)
	
	change(data.number)
	
	if body.is_player() and not map.level_has_battery():
		deactivate()
	
	if G.in_world():
		deactivate()

func deactivate():
	active = false
	set_visible(false)

func is_positively_wound():
	return val > 0

func is_negatively_wound():
	return val < 0

func change_battery(dv):
	val += dv
	
	if dv > 0:
		GAudio.play_dynamic_sound(body, "battery_up")
	elif dv < 0:
		GAudio.play_dynamic_sound(body, "battery_down")
	
	UI.update_player_battery(val)

func change(dv, instant = false):
	if not active: return

	var old_val = val
	var was_inverted = val < 0
	
	val += dv
	
	var is_inverted_now = val < 0
	var already_played_sound = false
	if was_inverted != is_inverted_now:
		feedback.create_from_3d(body.translation, "Invert!")
		GAudio.play_dynamic_sound(body, "invert")
		already_played_sound = true
	else:
		var fb_txt = str(dv)
		if dv >= 0: fb_txt = "+" + fb_txt
		feedback.create_from_3d(body.translation, fb_txt)
	
	if not already_played_sound:
		var abs_change = abs(val) - abs(old_val)
		if abs_change > 0:
			GAudio.play_dynamic_sound(body, "add_stack")
		elif abs_change < 0:
			GAudio.play_dynamic_sound(body, "remove_stack")
	
	body.visuals.update_models(val, instant)
	body.knobs.update_knob_materials(val)
	
	# TO DO: Flash its color as well
#	body.tween.interpolate_property(self, "scale",
#		1.3*self.scale, self.scale, GDict.cfg.tweens.popup_dur,
#		Tween.TRANS_ELASTIC, Tween.EASE_OUT)
#	body.tween.start()
	
	label.set_text(str(val))

func change_visibility(show: bool = false, instant: bool = false):
	var old = 1.3*Vector2.ONE
	var new = Vector2.ZERO
	if show:
		old = Vector2.ZERO
		new = Vector2.ONE
	
	var dur = GDict.cfg.tweens.popup_dur
	if instant: dur = 0.0001
	
	body.tween.interpolate_property(self, "scale",
		old, new, dur,
		Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	body.tween.start()

func is_zero():
	if not active: return true
	return val == 0

func count():
	if not active: return 0
	return val

func _physics_process(_dt):
	var y_offset = Vector3.UP*2.25
	var pos = body.translation + y_offset
	set_position(cam.unproject_position(pos))

func at_max_capacity():
	if not map.data.config.act_repeat: return abs(val) >= 1
	return abs(val) >= GDict.cfg.max_number
