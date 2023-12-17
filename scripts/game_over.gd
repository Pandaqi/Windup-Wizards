extends CanvasLayer

onready var color_rect = $ColorRect
onready var cam = get_node("../Camera")
onready var tween = get_node("../Tween")
onready var map = get_node("../Map")
onready var main_node = get_node("/root/Main")

const FADE_DUR : float = 0.5
const ALPHA : float = 0.85
const CUTOUT_RADIUS : float = 100.0

func activate():
	color_rect.material = color_rect.material.duplicate(true)
	
# warning-ignore:return_value_discarded
	get_tree().get_root().connect("size_changed", self, "on_resize")
	on_resize()

func on_resize():
	color_rect.material.set_shader_param("vp", get_viewport().size)
	color_rect.material.set_shader_param("pos", cam.unproject_position(map.get_player().translation))

func change_overlay(show: bool, we_won : bool):
	var color = Color(0.1,0.3,0.1)
	if not we_won: color = Color(0.3, 0.1, 0.1)
	
	color_rect.material.set_shader_param("col", color);
	color_rect.material.set_shader_param("pos", cam.unproject_position(main_node.get_player().translation))
	
	var start_col = Color(1,1,1,0)
	var end_col = Color(1,1,1,ALPHA)
	if not show:
		start_col = end_col
		end_col = Color(1,1,1,0)
	
	tween.interpolate_property(color_rect, "modulate",
		start_col, end_col, FADE_DUR,
		Tween.TRANS_LINEAR, Tween.EASE_OUT)
	
	var start_rad = 1000.0
	var end_rad = CUTOUT_RADIUS * G.global_scale_factor
	
	if not show:
		start_rad = end_rad
		end_rad = 1000.0
	
	color_rect.material.set_shader_param("rad", 1000.0)
	tween.interpolate_property(color_rect.material, "shader_param/rad",
		start_rad, end_rad, FADE_DUR,
		Tween.TRANS_ELASTIC, Tween.EASE_OUT)
		
	tween.start()
