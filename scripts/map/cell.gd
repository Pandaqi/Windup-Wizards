extends Spatial

var grid_pos : Vector2
var active : bool = false
var type : int

onready var entities = $Entities
onready var grid = $Grid
onready var knob = $Knob

var model

func set_grid_pos(p:Vector2):
	grid_pos = p

func activate(tp: int, has_knob: bool = false):
	if tp < 0: 
		disable()
		return
	
	active = true
	
	if has_knob: knob.add()
	
	set_type(tp)
	enable()

func set_type(tp:int):
	type = tp
	
	if model: model.queue_free()
	
	model = GDict.cube_models[type].instance()
	add_child(model)

func disable():
	set_visible(false)

func enable():
	set_visible(true)

func is_hole():
	return type == 1

func is_pause():
	return type == 2

func highlight():
	pass

func unhighlight():
	pass

func player_is_here():
	return entities.player_is_here()
