extends Node

var world : String = ""
var world_index : int = -1

var level : String = ""
var level_index : int = -1

var overview_data = {}
var cur_world_data = {}

#
# Prepare overview data (as that's where every game launch starts)
#
func _ready():
	overview_data = load_json("res://data/structure.json")

#
# Worlds
#
func set_world_by_name(key : String):
	world = key
	world_index = overview_data.worlds.find(key)
	
	load_world_data()

func set_world_by_index(index: int):
	world_index = index
	world = overview_data.worlds[index]
	
	load_world_data()

func load_world_data():
	cur_world_data = load_json("res://data/" + world + "/structure.json")

func get_world_name():
	if not cur_world_data: return "Err: no world loaded"
	return cur_world_data.name

func set_world_to_highest_saved():
	var highest_index = 0
	for key in GSave.save_data.unlocked:
		var index = overview_data.worlds.find(key)
		if index <= highest_index: continue
		highest_index = index
	
	set_world_by_index(highest_index)

#
# Levels
#
func set_level_by_name(key : String):
	level = key
	level_index = cur_world_data.levels.find(key)

func set_level_by_index(index: int):
	level_index = index
	level = cur_world_data.levels[level_index]

func get_level_index():
	return level_index

func get_level_name(index : int):
	return cur_world_data.levels[index]

func get_highest_level_saved():
	var highest_index = -1
	
	if not GSave.save_data.unlocked.has(world):
		GSave.unlock_world(world)
		return -1
	
	for key in GSave.save_data.unlocked[world]:
		var index = cur_world_data.levels.find(key)
		if index <= highest_index: continue
		highest_index = index
	
	return highest_index

func set_level_to_highest_saved():
	set_level_by_index(max(get_highest_level_saved(), 0))

func cur_level_is_last_of_world():
	print("LAST OF WORLD?")
	print(level_index)
	print(cur_world_data.levels.size())
	
	return level_index >= (cur_world_data.levels.size() - 1)

func get_custom_previous_level(level_name : String):
	var custom_level_index = cur_world_data.levels.find(level_name)
	var prev_level_index = custom_level_index - 1
	if prev_level_index < 0: return null
	
	return cur_world_data.levels[prev_level_index]

func load_next_level():
	level_index += 1
	if level_index >= cur_world_data.levels.size():
		level_index = 0
		
		world_index += 1
		if world_index >= overview_data.worlds.size(): 
			return false
		else:
			set_world_by_index(world_index)

	set_level_by_index(level_index)
	return true

#
# Actual JSON loading
#
func load_level():
	var path = "res://data/" + world + "/" + level + ".json"
	GDict.level_data = load_json(path)

func get_custom_level(index: int):
	var level_name = cur_world_data.levels[index]
	var path = "res://data/" + world + "/" + level_name + ".json"
	return load_json(path)

func load_json(fname):
	var file = File.new()
	file.open(fname, file.READ)
	var json = file.get_as_text()
	var json_result = JSON.parse(json).result
	
	file.close()
	
	return json_result

#
# Converts a world into level_data we can actually play
#
func load_world():
	print("Cur world data")
	print(cur_world_data)
	
	var has_prev_world = world_index > 0
	var has_next_world = world_index < (overview_data.worlds.size()-1)
	
	var offset = 2
	
	var num_levels = min(cur_world_data.levels.size(), get_highest_level_saved()+offset)
	
	# when debugging, just show all levels, so we can move around quickly
	if G.debugging_mode: 
		num_levels = cur_world_data.levels.size()
	
	var all_levels_unlocked = (get_highest_level_saved() >= cur_world_data.levels.size()-1)
	if G.debugging_mode: all_levels_unlocked = true
	
	if has_prev_world: num_levels += 1
	if has_next_world and all_levels_unlocked: num_levels += 1
	
	var width_in_levels = min(4, num_levels)
	var height_in_levels = ceil(num_levels / float(width_in_levels))
	
	print("NUM LEVELS")
	print(num_levels)
	
	print("HIGHEST LEVEL SAVED")
	print(get_highest_level_saved())
	
	print("Has next world?")
	print(has_next_world)
	
	# each level has a 3x3 box around it for the player to move in
	var width = width_in_levels * 2
	var height = height_in_levels * 2
	
	# but because the 3x3 boxes overlap, we pretend its 2x2 and add the missing row/col at the end
	height += 1
	width += 1
	
	var cells = []
	var entities = []
	
	cells.resize(width*height)
	entities.resize(width*height)
	
	var player_pos = Vector2(-100,-100)
	var last_level_played = GjsonLoader.level_index
	if last_level_played <= 0 or last_level_played >= num_levels:
		player_pos = Vector2.ZERO
	
	for x in width:
		for y in height:
			var idx = x + y*width
			
			# all corners of the 3x3 box (around a level) get a "pause" cell
			var type = 0
			if x % 2 == 0 and y % 2 == 0: type = 2
			
			cells[idx] = type
			
			# the actual player + level-starting entities
			var entities_here = []
			if (Vector2(x,y) - player_pos).length() <= 0.03:
				entities_here.append({ 'kind': 'player' })
			
			if x % 2 == 1 and y % 2 == 1:
				var cur_level_index = floor(x/2.0) + floor(y/2.0)*width_in_levels
				
				var real_index = cur_level_index
				if has_prev_world: real_index -= 1
				
				# we're using the fact that the cell we position on is always evaluated AFTER this cell, so we can set player pos here and know it will be used later
				if real_index == last_level_played and real_index > 0:
					player_pos = Vector2(x,y)+Vector2.ONE
				
				var cutoff = num_levels
				if has_prev_world:
					cutoff -= 1
				if has_next_world and all_levels_unlocked:
					cutoff -= 1
				
				if has_prev_world and cur_level_index == 0:
					entities_here.append({ 'kind': 'world', 'knobs': [true, false, false, false], 'level': world_index - 1 })
				
				elif has_next_world and all_levels_unlocked and (cur_level_index == (num_levels-1)):
					entities_here.append({ 'kind': 'world', 'knobs': [false,false,true,false], 'level': world_index + 1, 'rot': 2 })
				
				elif real_index < cutoff:
					entities_here.append({ 'kind': 'menu', 'knobs': [true,false,false,false], 'level': real_index })

			entities[idx] = entities_here
			
			# the things to shift between worlds
	
	var tut_array = []
	if world_index == 0:
		tut_array = [
			{
				'frame': 32,
				'location': [width+1,0],
				'scale': 1
			},
			{
				'frame': 9,
				'location': [-2,0],
				'scale': 1,
				'input': true
			}
		]
	
	var level_data = {
		'tutorial': tut_array,
		'width': width,
		'height': height,
		"cells": cells,
		"entities": entities,
		"solution": [],
		"config": {}
	}
	
	GDict.level_data = level_data
