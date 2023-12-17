extends CanvasLayer

var is_active = false
export (String) var type = "campaign"

var ad_modal_textures = {
	"campaign": preload("res://Assets/Tutorials_Shared/campaign_ad_modal.png"),
	"hint": preload("res://Assets/Tutorials_Shared/hint_ad_modal.png"),
	"undo": preload("res://Assets/Tutorials_Shared/undo_ad_modal.png"),
}

func _ready():
	hide()
	set_type(type)

func set_type(tp):
	type = tp
	get_node("Control/TextureRect").texture = ad_modal_textures[type]

func show():
	is_active = true
	get_node("Control").set_visible(true)

func _input(ev):
	if not is_active: return
	
	if ev.is_action_released("click") or (ev is InputEventKey):
		hide()
		get_tree().set_input_as_handled()

func hide():
	is_active = false
	get_node("Control").set_visible(false)
