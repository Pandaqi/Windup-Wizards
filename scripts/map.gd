extends Spatial

var cell_scene = preload("res://scenes/map/cell.tscn")
var map = []

var data
var config

var cur_player_highlight = null

onready var helpers = $Helpers
onready var spawner = $Spawner

onready var cells = $Cells
onready var entities = $Entities

onready var commands = get_node("../Commands")
onready var state = get_node("../State")
onready var tween = get_node("../Tween")
onready var parallel_tween = get_node("../ParallelTween")
onready var UI = get_node("../UI")
onready var cam = get_node("../Camera")
onready var feedback = get_node("../Feedback")

onready var game_over = get_node("../GameOver")

func activate():
	data = GDict.level_data
	
	for key in GDict.default_level_config:
		if not data.config.has(key):
			data.config[key] = GDict.default_level_config[key]
	
	config = GDict.grid_config
	
	state.set_turns(data.solution.size())
	
	create_cells()
	place_entities()

func create_cells():
	map = []
	map.resize(data.width)
	
	var rotate_cells_randomly = G.in_level()
	
	for x in range(data.width):
		
		map[x] = []
		map[x].resize(data.height)
		
		for y in range(data.height):
			var new_cell = cell_scene.instance()
			new_cell.set_grid_pos(Vector2(x,y))
			new_cell.set_translation(helpers.get_real_pos(Vector2(x,y)) + (1.0 / GDict.grid_config.tile_size) * Vector3.DOWN)
			
			if rotate_cells_randomly:
				new_cell.set_rotation(Vector3(0,1,0) * (randi() % 4) * 0.5*PI)
			
			var counter = helpers.get_index_from_pos(Vector2(x,y))
			var cell_type = data.cells[counter]
			var has_knob = false
			if data.has('cell_contents'):
				has_knob = data.cell_contents[counter]
			
			map[x][y] = new_cell
			cells.add_child(new_cell)
			
			new_cell.activate(cell_type, has_knob)

func get_cell(pos: Vector2):
	if helpers.out_of_bounds(pos): return null
	return map[pos.x][pos.y]

func player_here(pos: Vector2):
	if not get_cell(pos): return false
	return get_cell(pos).entities.has_specific(spawner.player)

func place_entities():
	for i in range(data.width*data.height):
		var ents = data.entities[i]
		if ents.size() <= 0: continue
		
		for e in ents:
			spawner.place(i, e)

# A single bad entity (still alive) forbids a win
func in_win_state():
	var all_entities = get_tree().get_nodes_in_group("Entities")
	for entity in all_entities:
		if entity.dead: continue
		if entity.bad: return false
	
	return true

func highlight_player_cell(pos):
	if cur_player_highlight:
		cur_player_highlight.grid.unhighlight()
	
	map[pos.x][pos.y].grid.highlight()
	cur_player_highlight = map[pos.x][pos.y]

func get_player():
	return spawner.player

func get_player_2d_pos(offset: Vector3):
	return cam.unproject_position(spawner.player.translation + offset)

func player_on_same_cell(node):
	return (get_player().grid_pos - node.grid_pos).length() < 0.03

func level_has_knobs():
	if not data.has("cell_contents"): return false
	
	var all_false = true
	for i in range(data.cells.size()):
		if data.cell_contents[i]:
			all_false = false
			break
	
	if all_false: return false
	
	return true

func level_has_battery():
	for i in range(data.entities.size()):
		for entity in data.entities[i]:
			if entity.kind == "battery":
				return true
	return false
