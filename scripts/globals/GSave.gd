extends Node

var save_data
var default_save_data = {
	'unlocked': {
		'first_turns': {}
	}
}

func _ready():
	load_game()

#
# Taking care of saving/loading games
# Save file is at: %APPDATA%\Godot\app_userdata\Square Ogre\
#
func save_level_completion():
	finish_level(GjsonLoader.world, GjsonLoader.level)

func finish_level(world, level):
	unlock_world(world)
	
	save_data.unlocked[world][level] = true
	save_game()

func unlock_world(world):
	if save_data.unlocked.has(world): return
	
	save_data.unlocked[world] = {}
	save_game()

func is_level_unlocked_by_index(level_index):
	var level_name = GjsonLoader.get_level_name(level_index)
	return is_level_unlocked(GjsonLoader.world, level_name)

func is_level_unlocked(world, level):
	if not save_data.unlocked.has(world): return false
	if not save_data.unlocked[world].has(level): return false
	return save_data.unlocked[world][level]

func is_level_playable_by_index(level_index):
	var level_name = GjsonLoader.get_level_name(level_index)
	return is_level_playable(GjsonLoader.world, level_name)

func is_level_playable(world, level):
	var prev_level = GjsonLoader.get_custom_previous_level(level)
	if not prev_level: return true
	
	return is_level_unlocked(world, level) or is_level_unlocked(world, prev_level)

func save_game(empty = false):
	var save_game = File.new()
	save_game.open(get_save_path(), File.WRITE)

	if empty: save_data = default_save_data

	save_game.store_line(to_json(save_data))
	save_game.close()

func get_save_path():
	return "user://savegame.save"

func load_game():
	var save_game = File.new()
	
	# if file doesn't exist, create it now, with empty content
	if not save_game.file_exists(get_save_path()):
		save_game(true)

	# otherwise, set the save_data variable immediately to the known value
	save_game.open(get_save_path(), File.READ)
	save_data = parse_json(save_game.get_line())
	save_game.close()
	
	# some failsafes, in case there are different save file versions floating around (or something else goes wrong
	if not save_data or not save_data.has("unlocked"):
		save_data = default_save_data
		save_game(true)
