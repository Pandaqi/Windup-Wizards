extends Node

var release_mode : bool = false
var debugging_mode : bool = true
var premium_mode : bool = true

var cur_mode : String = "level"
var last_player_pos : Vector2 = Vector2.ZERO
var hint_mode : bool = false

var level_load_complete : bool = false
var undo_mode : bool = false
var global_scale_factor : float = 1.0

var scenes = {
	'main': preload("res://Main.tscn")
}

func _ready():
	if release_mode: 
		cur_mode = "world"
		
		GjsonLoader.set_world_to_highest_saved()
		GjsonLoader.set_level_to_highest_saved()

func goto_level():
	cur_mode = "level"
# warning-ignore:return_value_discarded
	get_tree().change_scene_to(scenes.main)

func goto_world():
	cur_mode = "world"
# warning-ignore:return_value_discarded
	get_tree().change_scene_to(scenes.main)

func save_player_pos(p: Vector2):
	last_player_pos = p

func in_world():
	return cur_mode == "world"

func in_level():
	return cur_mode == "level"

func is_premium():
	return premium_mode

func is_mobile():
	return OS.get_name() == "Android" or OS.get_name() == "iOS"

func is_web():
	return OS.get_name() == "HTML5"

func is_console():
	return false
