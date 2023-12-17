extends CanvasLayer

onready var state = get_node("../State")
onready var map = get_node("../Map")
onready var cam = get_node("../Camera")
onready var commands = get_node("../Commands")
onready var ad_manager = get_node("../AdManager")

onready var tween = $Tween
onready var button_container = $ButtonContainer
onready var turn_container = $ButtonContainer/Turns
onready var turn_label = $ButtonContainer/Turns/Label

onready var knob_container = $KnobCounter
onready var knob_label = $KnobCounter/Label

onready var player_battery = $PlayerBattery
onready var battery_label = $PlayerBattery/Label

onready var action_feedback = $ActionFeedback
onready var world_title = $WorldTitle

onready var settings_container = get_node("../Settings/Container")

const TURN_FLASH_DUR : float = 0.25
const WORLD_FLASH_DUR : float = 1.0

var game_over_mode : bool = false
var game_over_we_won : bool = false
var time_game_over_started : float = -1

const BREAKPOINT_1 : Vector2 = Vector2(640, 500)
const BREAKPOINT_2 : Vector2 = Vector2(1920, 1080)

func activate():
	if G.in_world(): 
		button_container.set_visible(false)
		knob_container.set_visible(false)
		player_battery.set_visible(false)
		action_feedback.set_visible(false)
	
	elif G.in_level():
		action_feedback.modulate.a = 0.0
	
# warning-ignore:return_value_discarded
	get_tree().get_root().connect("size_changed", self, "on_resize")
	on_resize()
	
	flash_world_title()
	
	if not map.level_has_knobs():
		knob_container.set_visible(false)
	else:
		update_held_knobs(0)
	
	print("Level has battery?")
	print(map.level_has_battery())
	if not map.level_has_battery():
		player_battery.set_visible(false)
	else:
		update_player_battery(0)

func on_resize():
	var vp = get_viewport().size
	
	if game_over_mode:
		var player_pos = cam.unproject_position(map.get_player().translation)
		button_container.set_position(player_pos)
	
	else:
		button_container.set_position(vp)
		
		var world_title_pos = Vector2(0.5*vp.x, vp.y - 60)
		if G.in_level():
			world_title_pos.y = 60
		
		action_feedback.set_position(world_title_pos)
		world_title.set_position(world_title_pos)
	
	var target_vp = Vector2(1024, 600)
	var smallest_factor = min(vp.x/target_vp.x, vp.y/target_vp.y)
	
	var UI_bump_for_readability = 1.05
	smallest_factor *= UI_bump_for_readability
	
	var new_scale = Vector2.ONE * smallest_factor
	
	button_container.set_scale(new_scale)
	world_title.set_scale(new_scale)
	action_feedback.set_scale(new_scale)
	knob_container.set_scale(new_scale)
	player_battery.set_scale(new_scale)
	
	# position player battery next to knob container (if visible), at ZERO otherwise
	var battery_pos = Vector2.ZERO
	if map.level_has_knobs():
		battery_pos = new_scale.x * 0.5*Vector2(256,0)
	player_battery.set_position(battery_pos)
	
	if is_instance_valid(settings_container):
		settings_container.set_scale(new_scale*1.5)
	
		if G.is_mobile():
			var y_offset = -settings_container.get_scale().y*100
			settings_container.set_position(Vector2(0, vp.y+y_offset))
	
	G.global_scale_factor = smallest_factor
	
	print("VIEWPORT SIZE")
	print(vp)

func move_buttons_for_game_over(we_won : bool):
	time_game_over_started = OS.get_ticks_msec()
	
	game_over_mode = true
	game_over_we_won = we_won
	
	remove_child(button_container)
	map.game_over.add_child(button_container)
	
	button_container.get_node("Turns").set_visible(false)
	
	var buttons = ["Undo", "Hint", "Exit", "Restart"]
	var player_pos = cam.unproject_position(map.get_player().translation)
	var offset = 150.0
	var new_positions = {
		"Undo": Vector2.UP,
		"Hint": Vector2.DOWN,
		"Exit": Vector2.LEFT,
		"Restart": Vector2.RIGHT
	}
	
	if we_won:
		button_container.get_node("Hint").set_visible(false)
		button_container.get_node("Undo").set_type("continue")
	
	# TO DO: Give actual feedback that tells you if you won or not, otherwise people might not know => although this might just be in-game feedback in general, like "Out of turns!"
	
	button_container.set_position(player_pos)
	tween.interpolate_property(button_container, "rotation",
		0, 2*PI, 0.6,
		Tween.TRANS_LINEAR, Tween.EASE_OUT)
	
	for b in buttons:
		var node = button_container.get_node(b)
		var new_pos = new_positions[b] * offset
		commands.add_and_execute(ButtonMove.new(node, node.position, new_pos))

func unmove_buttons_for_game_over(we_won):
	game_over_mode = false
	game_over_we_won = we_won
	
	map.game_over.remove_child(button_container)
	add_child(button_container)
	
	button_container.set_position(get_viewport().size)
	
	button_container.get_node("Turns").set_visible(true)
	if we_won:
		button_container.get_node("Hint").set_visible(true)
	
	# ButtonMove commands are automatically undone

func in_game_over():
	return game_over_mode

func do_move(vec: Vector2):
	state.do_move(vec)

func undo_last_move(seen_ad = false):
	if state.can_undo_last_move():
		if not seen_ad and ad_manager.should_show_ad():
			if ad_manager.can_show_ad():
				return ad_manager.show_ad("undo")
			else:
				return ad_manager.show_ad_modal()
	
	GAudio.play_static_sound("button")
	state.undo_last_move()

func check_key_game_over_ui(vec):
	# don't allow immediate inputs here, as that's too quick and probably accidental
	var time_elapsed = OS.get_ticks_msec() - time_game_over_started
	if time_elapsed < 500.0: return
	
	if vec.x > 0.5:
		restart()
	
	elif vec.y > 0.5:
		if not game_over_we_won:
			hint()
	
	elif vec.x < -0.5:
		exit()
	
	elif vec.y < -0.5:
		if game_over_we_won:
			continue_to_next_level()
		else:
			undo_last_move()

func restart():
	GAudio.play_static_sound("button")
# warning-ignore:return_value_discarded
	get_tree().reload_current_scene()

func exit():
	GAudio.play_static_sound("button")
	G.goto_world()

func hint(seen_ad = false):
	if state.moving_not_allowed(): 
		state.feedback.create_at_player("Move in action!")
		return
	
	if not seen_ad and ad_manager.should_show_ad():
		if ad_manager.can_show_ad():
			return ad_manager.show_ad("hint")
		else:
			return ad_manager.show_ad_modal()
	
	GAudio.play_static_sound("button")
	state.execute_hint()

func continue_to_next_level(seen_ad = false):
	var should_show_ad_specific = GjsonLoader.cur_level_is_last_of_world()
	if not seen_ad and ad_manager.should_show_ad() and should_show_ad_specific:
		if ad_manager.can_show_ad():
			return ad_manager.show_ad("continue")
		else:
			return ad_manager.show_ad_modal()
	
	GAudio.play_static_sound("button")
	
	var res = GjsonLoader.load_next_level()
	if not res:
		G.goto_world()
		return
	
	G.goto_level()

func on_turn_change(val):
	turn_label.set_text(str(val))
	
	tween.interpolate_property(turn_container, "modulate",
		Color(3.0, 1.0, 1.0), Color(1.0, 1.0, 1.0), TURN_FLASH_DUR,
		Tween.TRANS_LINEAR, Tween.EASE_OUT)
	
	tween.interpolate_property(turn_container, "scale",
		Vector2.ONE*1.2, Vector2.ONE, TURN_FLASH_DUR,
		Tween.TRANS_LINEAR, Tween.EASE_OUT)
	
	tween.start()

func flash_action_feedback(txt : String):
	if not G.in_level(): return
	
	world_title.set_visible(false)

	action_feedback.set_scale(Vector2.ZERO)
	action_feedback.modulate.a = 1.0
	
	action_feedback.get_node("Label").set_text(txt)

	tween.interpolate_property(action_feedback, "scale",
		Vector2.ZERO, Vector2.ONE*G.global_scale_factor*0.5, 0.2,
		Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	
	tween.interpolate_property(action_feedback, "modulate",
		Color(1,1,1), Color(1,1,1,0), 0.5,
		Tween.TRANS_LINEAR, Tween.EASE_OUT,
		0.2)
	
	tween.start()

func flash_world_title(text_override : String = ""):
	world_title.set_visible(true)
	
	world_title.modulate.a = 1.0
	world_title.set_scale(Vector2.ZERO)
	
	var world_name = GjsonLoader.get_world_name()
	var level_index = GjsonLoader.get_level_index()
	var text = world_name
	
	if G.in_level():
		text = world_name + " (" + str(level_index + 1) + ")"
	
	if text_override != "":
		text = text_override
	
	world_title.get_node("Label").set_text(text)

	tween.interpolate_property(world_title, "scale",
		Vector2.ZERO, Vector2.ONE*G.global_scale_factor, WORLD_FLASH_DUR,
		Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	
	tween.interpolate_property(world_title, "modulate",
		Color(1,1,1), Color(1,1,1,0), 5.0,
		Tween.TRANS_LINEAR, Tween.EASE_OUT,
		WORLD_FLASH_DUR)
	
	tween.interpolate_property(world_title, "scale",
		Vector2.ONE, Vector2.ZERO, WORLD_FLASH_DUR,
		Tween.TRANS_BOUNCE, Tween.EASE_OUT,
		5.0)
		
	tween.start()

func update_player_battery(val):
	var mod = 1.0
	if val == 0: mod = 0.66
	
	player_battery.modulate.a = mod
	battery_label.set_text(str(val))
	
	tween.interpolate_property(battery_label, "modulate",
		Color(1.0, 3.0, 1.0), Color(1,1,1), TURN_FLASH_DUR,
		Tween.TRANS_LINEAR, Tween.EASE_OUT)
	tween.start()

func update_held_knobs(val):
	var mod = 1.0
	if val == 0: mod = 0.66
	
	knob_container.modulate.a = mod
	
	knob_label.set_text(str(val))
	
	tween.interpolate_property(knob_label, "modulate",
		Color(3.0, 1.0, 1.0), Color(1,1,1), TURN_FLASH_DUR,
		Tween.TRANS_LINEAR, Tween.EASE_OUT)
	tween.start()
