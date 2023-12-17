extends Spatial

var loose_knob_scene = preload("res://scenes/loose_knob.tscn")
var active : bool = false
var knob_model = null

onready var tween = get_node("/root/Main/Tween")

func _ready():
	self.set_translation(Vector3.UP*2)

func add():
	knob_model = loose_knob_scene.instance()
	add_child(knob_model)

	show_knob()

func has_one():
	return active

func show_knob():
	active = true
	create_tween(true)

func hide_knob():
	active = false
	create_tween(false)

func create_tween(show: bool = true):
	var start_scale = Vector3.ZERO
	var end_scale = Vector3.ONE
	if not show:
		start_scale = end_scale
		end_scale = Vector3.ZERO
	
	var start_pos = Vector3.UP*2
	var end_pos = Vector3.ZERO
	if not show:
		var temp = end_pos
		end_pos = start_pos
		start_pos = temp
	
	tween.interpolate_property(knob_model, "scale",
		start_scale, end_scale, GDict.cfg.tweens.knob_pickup,
		Tween.TRANS_BOUNCE, Tween.EASE_IN)
	
	tween.interpolate_property(knob_model, "translation",
		start_pos, end_pos, GDict.cfg.tweens.knob_pickup,
		Tween.TRANS_LINEAR, Tween.EASE_IN)
	
	tween.start()
