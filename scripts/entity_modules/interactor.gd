extends Node

onready var body = get_parent()
onready var commands = get_node("/root/Main/Commands")
onready var map = get_node("/root/Main/Map")

func evaluate_current_cell():
	var cell = body.get_current_cell()
	var must_stop = false
	var did_something = false
	
	# check cell type for ourselves
	# (cell types don't change dynamically)
	if not body.is_player() and cell.is_hole():
		yield(commands.add_and_execute(Kill.new(body)), "completed")
		return true
	
	#
	# check knob pickup
	#
	if cell.player_is_here() and cell.knob.has_one():
		did_something = true
		yield(commands.add_and_execute(PickupKnob.new(cell)), "completed")
	
	#
	# check interactions between us and anything else here (excluding player)
	# so, this loop is reasoned from OUR viewpoint
	#
	var player = map.get_player()
	var this_was_a_player_move = (body == player)
	
	var ent = cell.entities.get_excluding([player, body])
	var we_are_bad = body.bad
	
	if ent.size() > 0: must_stop = true
	
	if not this_was_a_player_move:
		for e in ent:
			var same_team = (e.bad == body.bad)
			if same_team and map.data.config.team_stack:
				did_something = true
				print("WANNA STACK")
				yield(commands.add_and_execute(Stack.new(body, e)), "completed")
				print("STACK ENDED")
			
			if same_team: continue
			
			did_something = true
			if we_are_bad:
				yield(commands.add_and_execute(Kill.new(body)), "completed")
				break
			else:
				yield(commands.add_and_execute(Kill.new(e)), "completed")
	
	#
	# and it ends with checking if the player stands here
	# and thus activates something
	#
	var player_can_activate_ents = map.data.config.man_act
	var last_move = body.last_move_dir
	var last_move_rev = (last_move + 2) % 4
	
	print("EVALUATING CURRENT CELL")
	
	var activated_passthrough = false

	if cell.player_is_here():
		for e in cell.entities.get_excluding([player]):
			if e.executor.is_already_active(): continue
			if e.is_passthrough(): 
				GAudio.play_dynamic_sound(e, "ghost")
				continue # passthrough entities never activate

			# give them a knob, if we have one and they have a free side
			# and this function is called by the player itself 
			# (so NOT a drag, because in that case this whole "evaluate_cell" thing isn't called)
			if player.knob_holder.has_one() and not e.knobs.has_in_dir(last_move_rev) and this_was_a_player_move:
				did_something = true
				must_stop = true
				commands.add_and_execute(KnobTransfer.new(e, last_move_rev))
			
			# if player has a battery value, give it to the entity
			# (lower our battery to 0, turn their knob X times)
			var player_battery_value = player.number.count()
			print("PLAYER BATTERY VALUE: " + str(player_battery_value))
			if player_battery_value != 0:
				print("TRANSFER BATTERY STUFF")
				
				did_something = true
				must_stop = true
				yield(commands.add_and_execute(PlayerBatteryChange.new(-player_battery_value)), "completed")
				
				var change_dir = sign(player_battery_value)
				for i in range(abs(player_battery_value)):
					commands.add_and_execute(TurnKnob.new(e, -1, change_dir))
					
					print("DOING POINT CHANGE")
					yield(map.commands.add_and_execute(PointChange.new(e, change_dir, false)), "completed")

			# activate them
			if player_can_activate_ents:
				print("FOUND SOMETHING TO ACTIVATE")
				
				if e.is_passthrough() and e.number.is_positively_wound(): 
					activated_passthrough = true
					GAudio.play_dynamic_sound(e, "ghost")
				
				did_something = true
				must_stop = true
				yield(e.executor.execute(), "completed")

	#
	# if all of this did absolutely nothing, we need to yield on something
	# so do an idle frame
	#
	print("MAKING DECISION")
	if not did_something: 
		yield(get_tree(), "idle_frame")
		return false
	
	print("STILL MAKING DECISION")
	if activated_passthrough:
		print("AT PASSTHROUGH CELL")
		must_stop = false

	return must_stop
