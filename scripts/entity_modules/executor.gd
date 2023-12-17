extends Node

onready var body = get_parent()
onready var commands = get_node("/root/Main/Commands")
onready var map = get_node("/root/Main/Map")
onready var feedback = get_node("/root/Main/Feedback")

var automatic : bool = false
var immediate : bool = false
var immediate_types = ['jump']
var support : bool = false

var activated : bool = false # whether or not it's currently activated and doing its actions, to preent repeat activations on player drag

func activate(data):
	if data.has('auto') and data.auto: make_automatic()
	if data.has('support') and data.support: make_support()
	if body.type in immediate_types:
		make_immediate()

func is_already_active():
	return activated

func make_automatic():
	automatic = true

func make_immediate():
	immediate = true

func make_support():
	if GDict.cfg.disable_support: return
	support = true
	
	# TO DO: some clear visual indicator when something is a support wizard

func should_auto_execute():
	if not automatic: return false
	if body.number.is_zero(): return false
	return true

func execute():
	print("REQUIRED AN EXECUTION")
	
	yield(get_tree(), "idle_frame") # to ensure we always do A yield
	
	if body.dead: return
	
	var num = body.number.count()
	if num == 0: 
		feedback.create_from_3d(body.translation, "Not wound up!")
		return

	activated = true
	
	var num_times = abs(num)
	var num_sign = sign(num)

	var player = map.get_player()
	var holding_player = holds_player(player)
	if not holding_player: player = null

	var knob_change_per_move = -num_sign
	if immediate: 
		knob_change_per_move = -num
		num_times = 1
	
	var no_repeating = not map.data.config.act_repeat
	if no_repeating: num_times = 1
	
	var entity_has_knobs = body.knobs.has_some()
	
	if support:
		highlight_adjacent_cells(true)
	
	# Note: we pretend we're sure the action will succeed, so that the knob animation plays alongside the action itself
	# If it ended up failing, we just reverse that decision
	for _i in range(num_times):
		if entity_has_knobs:
			commands.add_and_execute(TurnKnob.new(body, -1, knob_change_per_move))
		
		var results
		if support:
			results = yield(execute_on_adjacent_cells(), "completed")
		else:
			results = yield(execute_once(body, player), "completed")

		if results.failed:
			if entity_has_knobs: 
				commands.add_and_execute(TurnKnob.new(body, -1, -knob_change_per_move))
		else:
			yield(commands.add_and_execute(PointChange.new(body, knob_change_per_move)), "completed")
		
		if results.should_stop: 
			break
	
	if support:
		highlight_adjacent_cells(false)

	activated = false

func highlight_adjacent_cells(val):
	var nbs = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]
	var our_pos = body.grid_pos
	for nb in nbs:
		var nb_cell = map.get_cell(our_pos + nb)
		if not nb_cell or not nb_cell.active: continue
		
		if val:
			nb_cell.grid.highlight_support()
		else:
			nb_cell.grid.unhighlight_support()

func holds_player(player):
	return body.get_current_cell().entities.has_specific(player)

func execute_on_adjacent_cells():
	var nbs = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]
	var our_pos = body.grid_pos
	
	var num_fails = 0
	var num_stops = 0
	var num_executed = 0

	for nb in nbs:
		var nb_cell = map.get_cell(our_pos + nb)
		if not nb_cell or not nb_cell.active: continue
		if not nb_cell.entities.has_some(): continue

		var res = null
		print("=> Executing on neighbor ", nb)
		for e in nb_cell.entities.get_them():
			res = yield(e.executor.execute_once(body, null), "completed")
		
		if not res: continue
		
		num_executed += 1
		if res.failed:
			num_fails += 1
		if res.should_stop:
			num_stops += 1
	
	if num_executed <= 0:
		feedback.create_from_3d(body.translation, "No neighbours to activate")
		yield(get_tree(), "idle_frame")
	
	return {
		'failed': (num_fails >= num_executed),
		'should_stop': (num_stops >= num_executed)
	}
	

func execute_once(instigator, player):
	print("EXECUTING ONCE")

	var dir = instigator.rot
	var num = instigator.number.count()
	var vec_dir = map.helpers.get_vec_from_dir(dir)
	
	var int_dir = sign(num)
	if int_dir < 0: vec_dir *= -1
	if immediate: vec_dir *= abs(num)
	
	var type = instigator.type
	var invalid_execute_exception = (type == "jump" and abs(num) <= 1) or (type == "passthrough")
	
	if body.dead or invalid_execute_exception: 
		yield(get_tree(), "idle_frame")
		return { 'failed': true, 'should_stop': true }
	
	feedback.create_from_3d(body.translation, "Activate!")
	
	var cmd_list = []
	
	match type:
		"move":
			cmd_list.append(PosChange.new(body, vec_dir))
		
		"jump":
			cmd_list.append(Jump.new(body, vec_dir))
		
		"attract":
			print("Attract command!")
			print(body.rot)
			print(dir)
			print(vec_dir)
			cmd_list.append(Attract.new(body, vec_dir, false))
		
		"repel":
			cmd_list.append(Attract.new(body, vec_dir, true))
		
		"rotate":
			cmd_list.append(Rotate.new(body, int_dir))
		
		"destruct":
			if num > 0:
				GAudio.play_dynamic_sound(body, "destruct")
				cmd_list.append(Kill.new(body))
			elif num < 0:
				GAudio.play_dynamic_sound(body, "destruct")
				var player_at_same_location = (map.get_player().grid_pos - body.grid_pos).length() <= 0.03
				if player_at_same_location:
					cmd_list.append(Kill.new(map.get_player()))
		
		"convert":
			cmd_list.append(SwitchTeam.new(body))
		
		"battery":
			var override = (instigator != body)
			var override_num = instigator.number.count()
			
			cmd_list.append(Battery.new(body, override, override_num))
	
	var should_stop : bool = false
	var failed : bool = false
	for cmd in cmd_list:
		var stop = yield(commands.add_and_execute(cmd), "completed")
		
		if stop: should_stop = true
		
		if cmd.get('failed') and cmd.failed: 
			failed = true
			should_stop = true
			break
	
	print("ASKED FOR STOP")
	print(should_stop)
	
	print("THIS FAILED")
	print(failed)
	
	return {
		'failed': failed,
		'should_stop': should_stop
	}

func is_entry_allowed(other_entity):
	if other_entity.is_player():
		if body.is_passthrough() and body.number.is_negatively_wound(): 
			return false
	
	if body.is_player() or other_entity.is_player(): return true
	if not map.data.config.stop_after_enc: return true
	
	var same_team = (body.bad == other_entity.bad)
	if same_team:
		if not map.data.config.team_stack: 
			feedback.create_from_3d(body.translation, "Only one thing per square allowed!")
			return false
	
	return true
