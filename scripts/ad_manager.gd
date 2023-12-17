extends CanvasLayer

# REAL AD ID = ca-app-pub-7465988806111884/1741867675
# TEST AD ID = ca-app-pub-3940256099942544/5224354917

onready var admob = $AdMob
onready var modal = $TextureRect
onready var timer = $Timer
var return_type : String = ""

onready var UI = get_node("../UI")

var active : bool = false 
var listen_to_input : bool = false

func _ready():
	hide_ad_modal()
	fill_up_rewarded_ads()

func should_show_ad():
	return G.is_mobile() and not G.is_premium()

func can_show_ad():
	if not G.is_mobile(): return false
	return admob.is_rewarded_video_loaded()

func show_ad(tp):
	return_type = tp
	admob.show_rewarded_video()

func _on_AdMob_rewarded(currency, ammount):
	var ad_is_complete = true
	if return_type == "hint":
		UI.hint(ad_is_complete)
	
	elif return_type == "continue":
		UI.continue_to_next_level(ad_is_complete)
	
	elif return_type == "undo":
		UI.undo_last_move(ad_is_complete)

func _on_AdMob_rewarded_video_failed_to_load(error_code):
	print("Rewarded video failed to load")
	print(error_code)

#
# Ad modal showing
#
func show_ad_modal():
	print("WANNA SHOW AD MODAL")
	
	active = true
	get_tree().paused = true
	
	modal.set_visible(true)
	timer.start()

func hide_ad_modal():
	print("WANNA HIDE AD MODAL")
	
	get_tree().paused = false
	active = false
	
	modal.set_visible(false)
	listen_to_input = false

func _input(ev):
	if not active: return
	if not listen_to_input: return
	if (ev is InputEventScreenTouch) or (ev is InputEventMouseButton):
		hide_ad_modal()

#
# For making sure we always keep our reservoir of ads filled
#
func _on_AdMob_rewarded_video_closed():
	fill_up_rewarded_ads()

func _on_AdMob_rewarded_video_left_application():
	fill_up_rewarded_ads()

func _on_AdMob_rewarded_video_started():
	fill_up_rewarded_ads()

func fill_up_rewarded_ads():
	if admob.is_rewarded_video_loaded(): return
	admob.load_rewarded_video()

func _on_Timer_timeout():
	listen_to_input = true
