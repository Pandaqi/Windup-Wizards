extends Spatial

var base_frame
var types = ["move", "attract", "repel", "passthrough", "destruct", "jump", "rotate", "convert", "battery"]

onready var sprite = $Sprite3D
onready var anim_player = $AnimationPlayer

func set_type(type : String):
	var dont_display = (types.find(type) < 0)
	if dont_display:
		set_visible(false)
		return
	
	base_frame = types.find(type)*2
	sprite.set_frame(base_frame)
	
	var anim_dir = "outward"
	if type == "attract":
		anim_dir = "inward"
	
	if anim_dir == "outward":
		anim_player.play("HintShower")
	else:
		anim_player.play_backwards("HintShower")

func set_invert(inv: bool):
	if base_frame == null: return # for when I'm testing a new thing and don't have the icon yet
	
	if inv:
		sprite.set_frame(base_frame + 1)
	else:
		sprite.set_frame(base_frame)
