extends Node2D

onready var state = get_node("../State")
onready var UI = get_node("../UI")

var cur_flick_dir = Vector2.ZERO
var last_flick_time = 0

var swipe_start = null
var minimum_swipe_dist = 100

func _unhandled_input(ev):
	check_player_move(ev)
	check_ui(ev)

func check_player_move(ev):
	check_keyboard(ev)
	check_flick(ev)
	check_swipe(ev)

func check_flick(ev):
	if not (ev is InputEventJoypadMotion): return
	
	var threshold_high = 0.8
	var threshold_low = 0.2
	
	# check if an older flick ended?
	var h = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	var v = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	
	var joystick_vec = Vector2(h,v).normalized()
	var final_input_vec = Vector2.ZERO
	
	if joystick_vec.length() <= threshold_low:
		var time_diff = (OS.get_ticks_msec() - last_flick_time)
		var flick_threshold = 600 
		if time_diff < flick_threshold and cur_flick_dir != Vector2.ZERO:
			final_input_vec = cur_flick_dir
			cur_flick_dir = Vector2.ZERO
			last_flick_time = 0
	
	# start a new flick?
	if Input.get_action_strength("ui_left") > threshold_high:
		cur_flick_dir = Vector2.LEFT
		last_flick_time = OS.get_ticks_msec()
	elif Input.get_action_strength("ui_right") > threshold_high:
		cur_flick_dir = Vector2.RIGHT
		last_flick_time = OS.get_ticks_msec()
	elif Input.get_action_strength("ui_up") > threshold_high:
		cur_flick_dir = Vector2.UP
		last_flick_time = OS.get_ticks_msec()
	elif Input.get_action_strength("ui_down") > threshold_high:
		cur_flick_dir = Vector2.DOWN
		last_flick_time = OS.get_ticks_msec()
	
	if final_input_vec.length() <= 0.5: return
	
	if UI.game_over_mode:
		UI.check_key_game_over_ui(final_input_vec)
	else:
		UI.do_move(final_input_vec)

func check_swipe(ev):
	if ev is InputEventMouseButton:
		if ev.is_action_pressed("click"):
			swipe_start = get_global_mouse_position()
		elif ev.is_action_released("click"):
			calculate_swipe(get_global_mouse_position())
	
	elif ev is InputEventScreenTouch:
		if ev.pressed:
			swipe_start = ev.position
		else:
			calculate_swipe(ev.position)

func calculate_swipe(swipe_end):
	if swipe_start == null:  return
	
	var swipe = swipe_end - swipe_start
	if abs(swipe.x) < minimum_swipe_dist and abs(swipe.y) < minimum_swipe_dist: return
	
	var horizontal : bool = false
	if abs(swipe.x) > abs(swipe.y): horizontal = true
	
	var final_input_vec = Vector2.ZERO
	if horizontal:
		if swipe.x > 0: final_input_vec = Vector2.RIGHT
		else: final_input_vec = Vector2.LEFT
	else:
		if swipe.y > 0: final_input_vec = Vector2.DOWN
		else: final_input_vec = Vector2.UP
	
	if final_input_vec.length() <= 0.5: return
	
	UI.do_move(final_input_vec)

func check_keyboard(ev):
	var vec = Vector2.ZERO
	if ev.is_action_released("ui_left"):
		vec = Vector2.LEFT
	elif ev.is_action_released("ui_right"):
		vec = Vector2.RIGHT
	elif ev.is_action_released("ui_up"):
		vec = Vector2.UP
	elif ev.is_action_released("ui_down"):
		vec = Vector2.DOWN
	
	if vec.length() <= 0.5: return
	
	if UI.game_over_mode:
		UI.check_key_game_over_ui(vec)
	else:
		UI.do_move(vec)

func check_ui(ev):
	check_menu_ui(ev)
	check_level_ui(ev)

func check_menu_ui(ev):
	if not G.in_world(): return
	
	if ev.is_action_released("settings"):
		get_node("/root/Main/Settings").toggle()

func check_level_ui(ev):
	if not G.in_level(): return
	
	if ev.is_action_released("undo"):
		UI.undo_last_move()
	elif ev.is_action_released("restart"):
		UI.restart()
	elif ev.is_action_released("exit"):
		UI.exit()
	
	if ev.is_action_released("hint"):
		if not UI.game_over_mode or not UI.game_over_we_won:
			UI.hint()
	
	if ev.is_action_released("continue"):
		if UI.game_over_mode and UI.game_over_we_won:
			UI.continue_to_next_level()
