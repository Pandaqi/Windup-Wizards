extends CanvasLayer

var fb_scene = preload("res://scenes/feedback.tscn")
var offset_3d = Vector3.UP*1.75

onready var cam = get_node("../Camera")
onready var map = get_node("../Map")

var last_player_feedback = -1
const MIN_TIME_BETWEEN_PLAYER_FEEDBACKS = 550.0 # in milliseconds

func create_at_player(txt):
	var too_soon = (OS.get_ticks_msec() - last_player_feedback) < MIN_TIME_BETWEEN_PLAYER_FEEDBACKS
	if too_soon: return
	
	last_player_feedback = OS.get_ticks_msec()
	create(map.get_player_2d_pos(offset_3d), txt)

func create_from_3d(pos: Vector3, txt):
	create(cam.unproject_position(pos + offset_3d), txt)

func create(pos: Vector2, txt):
	var fb = fb_scene.instance()
	fb.get_node("Label").set_text(str(txt))
	fb.set_position(pos)
	add_child(fb)
