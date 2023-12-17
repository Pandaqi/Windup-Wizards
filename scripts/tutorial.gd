extends Spatial

onready var tut_scene = preload("res://scenes/tutorial.tscn")
onready var map = get_node("../Map")
onready var camera = get_node("../Camera")

onready var tween = $Tween

var tuts = []
var input_tut = null

func activate():
	if not map.data.has('tutorial'): return
	
	var tuts_data = []
	tuts_data = map.data.tutorial
	
	for obj in tuts_data:
		place_tutorial(obj)

func place_tutorial(obj):
	var sprite = tut_scene.instance()
	sprite.set_frame(obj.frame)
	
	var grid_pos = Vector2(obj.location[0], obj.location[1])
	var real_pos = map.helpers.get_real_pos(grid_pos)
	real_pos += Vector3.UP
	
	if obj.has('scale'): sprite.set_scale(Vector3.ONE * obj.scale)
	if obj.has('input'): 
		set_input_tut(sprite)
	
	sprite.set_translation(real_pos)
	add_child(sprite)
	
	tuts.append(sprite)
	
	var target_scale = sprite.scale
	sprite.set_scale(Vector3.ZERO)
	tween.interpolate_property(sprite, "scale",
		Vector3.ZERO, target_scale, 1.0,
		Tween.TRANS_ELASTIC, Tween.EASE_OUT,
		0.5)
	tween.start()

func set_input_tut(node):
	input_tut = node
	
	if G.is_mobile():
		input_tut.set_frame(11)
	elif G.is_console():
		input_tut.set_frame(10)
	else:
		input_tut.set_frame(9)

func _input(ev):
	update_input_tutorial_to_device(ev)

func update_input_tutorial_to_device(ev):
	if not input_tut: return
	
	if ev is InputEventScreenTouch or ev is InputEventScreenDrag:
		input_tut.set_frame(11)
	
	if ev is InputEventJoypadButton or ev is InputEventJoypadMotion:
		input_tut.set_frame(10)
	
	if ev is InputEventKey or ev is InputEventMouseMotion or ev is InputEventMouseButton:
		input_tut.set_frame(9)
