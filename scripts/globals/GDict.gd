extends Node

var grid_config = {
	'tile_size': 0.5
}

var default_level_config = {
	"rev_wind": true,
	"man_act": true,
	"act_repeat": true,
	"p_drag": true,
	"drag_chain": true,
	"team_stack": false, #whether items in the same team can stack on top of each other
	"stop_after_enc": true # whether to automatically stop whenever we encounter something
}

var cube_models = [
	preload("res://scenes/cubes/default.tscn"),
	preload("res://scenes/cubes/hole.tscn"),
	preload("res://scenes/cubes/pause.tscn")
]

var action_icons = {
	"move": preload("res://scenes/action_icons/move.tscn"),
	"success": preload("res://scenes/action_icons/success.tscn"),
	"attract": preload("res://scenes/action_icons/attract.tscn"),
	"repel": preload("res://scenes/action_icons/repel.tscn"),
	"jump": preload("res://scenes/action_icons/jump.tscn"),
	"rotate": preload("res://scenes/action_icons/rotate.tscn"),
	"destruct": preload("res://scenes/action_icons/bomb.tscn"),
	"passthrough": preload("res://scenes/action_icons/ghost.tscn"),
	"convert": preload("res://scenes/action_icons/convert.tscn"),
	"battery": preload("res://scenes/action_icons/battery.tscn")
}

var extruded_numbers = [
	null,
	preload("res://scenes/numbers/1.tscn"),
	preload("res://scenes/numbers/2.tscn"),
	preload("res://scenes/numbers/3.tscn"),
	preload("res://scenes/numbers/4.tscn"),
	preload("res://scenes/numbers/5.tscn"),
	preload("res://scenes/numbers/6.tscn"),
	preload("res://scenes/numbers/7.tscn"),
	preload("res://scenes/numbers/8.tscn"),
	preload("res://scenes/numbers/9.tscn"),
	preload("res://scenes/numbers/10.tscn"),
]

var level_data = {
	"width": 3,
	"height": 3,
	"cells": [-1,0,0,0,0,0,0,0,-1],
	"entities": [
		[],[],[],
		[{"kind": "player" }],[{"kind": "jump", "knobs": [false,false,false,true], "support": true, "rot": 3 }],[{"kind": "move", "bad": true }],
		[],[],[]
	],
	"solution": [0,1,2,3,0,1,2,3],
	"config": {
		"rev_wind": true,
		"man_act": true,
		"act_repeat": true,
		"p_drag": true,
		"drag_chain": true
	}
}

var cfg = {
	'player_has_points': false,
	'disable_support': false,
	'max_number': 4, 
	'tweens': {
		'move_dur': 0.3,
		'rot_dur': 0.3,
		'popup_dur': 0.5,
		'die_dur': 1.0,
		'stop_dur': 0.15,
		'knob_add': 1.0,
		'knob_rot_dur': 0.5,
		'knob_pickup': 0.4,
		'undo_speedup': 4.0,
		'model_appear_dur': 0.45,
		'model_invert_dur': 0.3,
	}
}
