extends Node

var val : int = 0

onready var UI = get_node("/root/Main/UI")

func add():
	val += 1
	UI.update_held_knobs(val)

func has_one():
	return (val > 0)

func remove():
	val -= 1
	UI.update_held_knobs(val)
