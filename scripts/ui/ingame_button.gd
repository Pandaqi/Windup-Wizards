extends Node2D

const TWEEN_DUR : float = 0.4

var hovered : bool = false
var frames = ["turns", "undo", "restart", "exit", "hint", "continue"]

onready var UI = get_node("/root/Main/UI")
onready var sprite = $Sprite
onready var reminder = $Reminder
onready var ad = $Ad

onready var ad_manager = get_node("/root/Main/AdManager")

const FADED_ALPHA = 0.5

export var type : String

var ad_types = ["undo", "hint"]

func _ready():
	set_type(type)
	
	if G.is_mobile():
		reminder.set_visible(false)
	
	show_reminders()

func show_reminders():
	var tween = UI.get_node("Tween")
	
	tween.stop(reminder, "scale")
	tween.stop(reminder, "position")
	tween.stop(reminder, "modulate")
	
	reminder.scale = Vector2.ZERO
	tween.interpolate_property(reminder, "scale",
		Vector2.ZERO, Vector2.ONE*0.33, 0.1,
		Tween.TRANS_LINEAR, Tween.EASE_OUT)
	
	reminder.position = Vector2.ZERO
	tween.interpolate_property(reminder, "position",
		Vector2.ZERO, Vector2(0,15), 1.5,
		Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	
	reminder.modulate.a = 1.0
	tween.interpolate_property(reminder, "modulate",
		Color(1,1,1,1), Color(1,1,1,FADED_ALPHA), 2.0,
		Tween.TRANS_LINEAR, Tween.EASE_OUT,
		10.0)
	
	tween.start()

func set_type(tp):
	if tp == "": return
	type = tp

	sprite.set_frame(frames.find(type))
	reminder.set_frame(frames.find(type))
	
	var show_ad_icon = ad_manager.should_show_ad() and ((type in ad_types) or (type == "continue" and GjsonLoader.cur_level_is_last_of_world()))
	ad.set_visible(true)
	
	if not show_ad_icon: ad.set_visible(false)

func _on_Button_mouse_entered():
	set_hover(true)

func _on_Button_mouse_exited():
	set_hover(false)

func _on_Button_pressed():
	if type == "undo":
		UI.undo_last_move()
	elif type == "restart":
		UI.restart()
	elif type == "exit":
		UI.exit()
	elif type == "hint":
		UI.hint()
	elif type == "continue":
		UI.continue_to_next_level()

func set_hover(val):
	hovered = val
	
	var old_scale = self.scale
	var new_scale = Vector2.ONE*1.4
	if not hovered: new_scale = Vector2.ONE
	
	UI.tween.interpolate_property(self, "scale",
		old_scale, new_scale, TWEEN_DUR,
		Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	UI.tween.interpolate_property(self, "rotation",
		0, 2*PI, TWEEN_DUR*0.25,
		Tween.TRANS_LINEAR, Tween.EASE_OUT)
	UI.tween.start()



