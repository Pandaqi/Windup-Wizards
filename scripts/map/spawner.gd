extends Node

var entity_scene = preload("res://scenes/entity.tscn")
var player

onready var map = get_parent()

func place(index:int, entity_data:Dictionary):
	var e = entity_scene.instance()
	
	var grid_pos = map.helpers.get_pos_from_index(index)
	e.set_grid_pos(grid_pos)
	e.set_translation(map.helpers.get_real_pos(grid_pos))
	map.get_cell(grid_pos).entities.add(e)
	
	map.entities.add_child(e)
	
	e.activate(entity_data)
	
	if entity_data.kind == "player":
		player = e
