extends Node

onready var map = get_node("../Map")
onready var commands = get_node("../Commands")
onready var tween = get_node("../Tween")
onready var parallel_tween = get_node("../ParallelTween")
onready var UI = get_node("../UI")
onready var feedback = get_node("../Feedback")

var win_particles = preload("res://particles/win_particles.tscn")

var turn : int = 0
var game_over_mode : bool = false
var moves : Array = []

var last_saved_input = null
var last_saved_time = -1

const SAVED_INPUT_THRESHOLD : float = 0.5

func activate():
	auto_execute_hint()

func moving_not_allowed():
	return tween.is_active() or parallel_tween.is_active() or commands.is_busy()

func in_game_over():
	return game_over_mode

func convert_vec_to_idx(vec: Vector2) -> int:
	if vec.x > 0.5: return 0
	elif vec.y > 0.5: return 1
	elif vec.x < -0.5: return 2
	else: return 3

func convert_idx_to_vec(idx: int) -> Vector2:
	if idx == 0: return Vector2.RIGHT
	elif idx == 1: return Vector2.DOWN
	elif idx == 2: return Vector2.LEFT
	else: return Vector2.UP

func save_move(vec):
	if game_over_mode: return false
	
	last_saved_input = vec
	last_saved_time = OS.get_ticks_msec()
	
	feedback.create_at_player("Move (" + get_move_name(vec) +  ") planned!")
	return true

func check_saved_input():
	if game_over_mode: return
	if not last_saved_input: return
	
	#var diff = (OS.get_ticks_msec() - last_saved_time)/1000.0
	#if diff > SAVED_INPUT_THRESHOLD: return
	
	var vec = last_saved_input
	last_saved_input = null
	
	do_move(vec)

# we check if we can actually move first, which might seem repeated code
# but it ensures we only open a new move when we actually move, preventing loads of errors down the road
func do_move(vec: Vector2, suppress_feedback: bool = false):
	if in_game_over():
		feedback.create_at_player("Game is already over!")
		return
	
	var p = map.get_player()
	if not map.helpers.entity_can_move_in_dir(p, vec): 
		if map.data.config.stop_after_enc:
			feedback.create_at_player("Can't move there!")
		return
	
	if moving_not_allowed(): 
		var res = save_move(vec)
		if not res: feedback.create_at_player("Move in action!")
		return
	
	moves.append(convert_vec_to_idx(vec))
	commands.open_new_move()
	
	if not suppress_feedback:
		UI.flash_action_feedback("Move (" + get_move_name(vec) + ")")

	while true:
		var should_stop = yield(commands.add_and_execute(PosChange.new(p, vec)), "completed")
		if should_stop: break
	
	yield(check_auto_entities(), "completed")
	
	if tween.is_active(): yield(tween, "tween_all_completed")
	if parallel_tween.is_active(): yield(parallel_tween, "tween_all_completed")
	
	commands.close_move()
	update_turn(-1)
	
	check_end_state()
	
	
	check_saved_input()

func get_move_name(vec: Vector2):
	if vec.x > 0.5: return "right"
	elif vec.y > 0.5: return "down"
	elif vec.x < -0.5: return "left"
	else: return "up"

func can_undo_last_move():
	if moving_not_allowed(): return false
	return true

func undo_last_move():
	if moving_not_allowed():
		feedback.create_at_player("Move in action!")
		
		print("Can't UNDO")
		if tween.is_active(): print("Tween still active")
		if parallel_tween.is_active(): print("Parallel tween still active")
		if commands.is_busy(): print("Commands still busy")
		
		return
	
	GAudio.play_dynamic_sound(map.get_player(), "player_move")
	UI.flash_action_feedback("Undo")
	
	moves.pop_back()
	
	var success = yield(commands.pop_and_rollback(), "completed")
	if not success: return
	update_turn(+1)

func auto_execute_hint():
	if not G.hint_mode: return
	
	G.hint_mode = false
	yield(tween, "tween_all_completed")
	if parallel_tween.is_active():
		yield(parallel_tween, "tween_all_completed")
	
	var first_move = map.data.solution[0]
	UI.flash_action_feedback("Hint")
	do_move(convert_idx_to_vec(first_move), true)

func execute_hint():
	if moving_not_allowed(): return
	
	var current_solution_matches = true
	var real_solution = map.data.solution
	var already_done = (moves.size() == real_solution.size())
	
	var next_move = real_solution[0]
	for i in range(moves.size()):
		if moves[i] != real_solution[i]:
			current_solution_matches = false
			break

		if (i+1) >= real_solution.size():
			already_done = true
			break
		
		next_move = real_solution[i+1]
	
	if current_solution_matches and not already_done:
		UI.flash_action_feedback("Hint")
		return do_move(convert_idx_to_vec(next_move), true)
	
	G.hint_mode = true
# warning-ignore:return_value_discarded
	get_tree().reload_current_scene()

func check_auto_entities():
	var entities = get_tree().get_nodes_in_group("Entities")
	var did_something = false
	for e in entities:
		if not e.executor.should_auto_execute(): continue
		did_something = true
		yield(e.executor.execute(), "completed")
	
	if not did_something: yield(get_tree(), "idle_frame")

func set_turns(t):
	turn = t
	UI.on_turn_change(turn)
	print("NUM TURNS: " + str(turn))

func update_turn(dt):
	turn += dt
	UI.on_turn_change(turn)
	print("TURN: " + str(turn))

func check_end_state():
	if G.in_world(): return
	
	if map.get_player().is_dead():
		feedback.create_at_player("Oh no! You're dead!")
		game_over(false)
		return
	
	if map.in_win_state():
		feedback.create_at_player("Magic trick complete!")
		game_over(true)
		return
	
	var out_of_turns = (turn <= 0)
	if out_of_turns:
		feedback.create_at_player("Out of turns!")
		game_over(false)

func create_win_particles():
	var player = map.get_player()
	var p = win_particles.instance()
	p.set_translation(player.translation)
	add_child(p)

func game_over(we_won : bool = false):
	if we_won: 
		GSave.save_level_completion()
		create_win_particles()
	
	commands.add_and_execute(GameOver.new(we_won))
