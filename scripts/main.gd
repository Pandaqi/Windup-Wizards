extends Spatial

onready var map = $Map
onready var camera = $Camera
onready var tutorial = $Tutorial
onready var UI = $UI
onready var settings = $Settings
onready var game_over = $GameOver
onready var state = $State

export var world : String = ""
export var level : String = ""

onready var tween = $Tween
onready var parallel_tween = $ParallelTween

func _ready():
	G.level_load_complete = false
	
	if GjsonLoader.world_index == -1:
		if world == "":
			GjsonLoader.set_world_by_index(0)
		else:
			GjsonLoader.set_world_by_name(world)
	
	if GjsonLoader.level_index == -1:
		if level == "":
			GjsonLoader.set_level_by_index(0)
		else:
			GjsonLoader.set_level_by_name(level)
	
	if G.in_level():
		GjsonLoader.load_level()
	elif G.in_world():
		GjsonLoader.load_world()
	
	map.activate()
	camera.activate()
	tutorial.activate()
	UI.activate()
	game_over.activate()
	state.activate()
	
	if G.in_level():
		settings.queue_free()
	else:
		settings.activate()
	
	if tween.is_active():
		yield(tween, "tween_all_completed")
	
	if parallel_tween.is_active():
		yield(tween, "tween_all_completed")
	
	on_level_load_complete()

func on_level_load_complete():
	G.level_load_complete = true
	state.check_saved_input()

func get_player():
	return map.get_player()

func show():
	pass

func hide():
	pass
