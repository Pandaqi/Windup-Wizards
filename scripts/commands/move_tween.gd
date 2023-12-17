class_name MoveTween

var e
var a
var b
var drag : bool
var tweens : Array

func _init(entity, start, end, d):
	e = entity
	a = start
	b = end
	drag = d
	tweens = []

func execute(map):
	var dur = GDict.cfg.tweens.move_dur
	# if drag: dur += 0.25
	
	var tw = get_correct_tween(map)
	var we_will_eat_something = (not e.bad) and map.get_cell(b).entities.has_bad()
	var we_will_be_eaten = e.bad and map.get_cell(b).entities.has_good()
	var team_stack = map.get_cell(b).entities.same_team(e)
	var new_real_pos = map.helpers.get_real_pos(b)
	var already_created_tween = false
	
	var is_jump = (a - b).length() > 1.05
	
	if not e.is_player():
		if team_stack:
			var other_body = map.get_cell(b).entities.get_excluding([e])[0]
			new_real_pos += other_body.visuals.get_top_height(false, true)
			
			play_half_jumpy_tween(tw, e, new_real_pos, dur)
			tweens.append({ 'type': 'half_jumpy', 'node': e })
			already_created_tween = true
		
		elif we_will_eat_something:
			play_jumpy_tween(tw, e, new_real_pos, dur)
			tweens.append({ 'type':'jumpy', 'node': e })
			already_created_tween = true
			
			var who_will_we_eat = map.get_cell(b).entities.get_eat_victim(e)
			play_prescale_tween(tw, who_will_we_eat, dur, true)
			tweens.append({ 'type': 'prescale', 'node': who_will_we_eat })
			
		elif we_will_be_eaten:
			var who_will_eat_us = map.get_cell(b).entities.get_eater(e)
			play_static_jumpy_tween(tw, who_will_eat_us, dur)
			tweens.append({ 'type':'static_jumpy', 'node': who_will_eat_us })
			
			play_prescale_tween(tw, e, dur, true)
			tweens.append({ 'type': 'prescale', 'node': e })
	
	if not already_created_tween:
		if is_jump:
			play_jumpy_tween(tw, e, new_real_pos, dur)
			tweens.append({ 'type':'jumpy', 'node':e })
		
		else:
			play_move_tween(tw, e, new_real_pos, dur)
			tweens.append({ 'type':'normal', 'node':e })
	
	yield(map.get_tree(), "idle_frame")

func rollback(map):
	var tw = get_correct_tween(map)
	var dur = GDict.cfg.tweens.move_dur
	
	for i in range(tweens.size()-1,-1,-1):
		var tween_data = tweens[i]
		var new_real_pos = map.helpers.get_real_pos(a)
		if tween_data.type == "normal":
			play_move_tween(tw, tween_data.node, new_real_pos, dur)
		
		elif tween_data.type == "jumpy":
			play_jumpy_tween(tw, tween_data.node, new_real_pos, dur)
		
		elif tween_data.type == "static_jumpy":
			play_static_jumpy_tween(tw, tween_data.node, dur)
		
		elif tween_data.type == "half_jumpy":
			play_half_jumpy_tween(tw, tween_data.node, new_real_pos, dur)
		
		elif tween_data.type == "prescale":
			play_prescale_tween(tw, tween_data.node, dur, false)
	
	yield(map.get_tree(), "idle_frame")

func play_move_tween(tw, node, new_real_pos, dur):
	tw.interpolate_property(node, "translation",
		e.translation, new_real_pos, dur,
		Tween.TRANS_CUBIC, Tween.EASE_OUT)
	tw.start()

func play_static_jumpy_tween(tw, node, dur):
	tw.interpolate_property(node, "translation",
		node.translation, node.translation + Vector3.UP*2, 0.5*dur,
		Tween.TRANS_CUBIC, Tween.EASE_OUT)
	
	tw.interpolate_property(node, "translation",
		node.translation + Vector3.UP*2, node.translation, 0.5*dur,
		Tween.TRANS_CUBIC, Tween.EASE_IN,
		0.5*dur)
	tw.start()

func play_half_jumpy_tween(tw, node, new_real_pos, dur):
	tw.interpolate_property(node, "translation",
		node.translation, new_real_pos, dur,
		Tween.TRANS_CUBIC, Tween.EASE_OUT)
	tw.start()

func play_jumpy_tween(tw, node, new_real_pos, dur):
	var move_vec = (new_real_pos - e.translation)
	
	tw.interpolate_property(node, "translation",
		node.translation, node.translation + 0.5*move_vec + Vector3.UP*2, 0.5*dur,
		Tween.TRANS_CUBIC, Tween.EASE_OUT)
	
	tw.interpolate_property(node, "translation",
		node.translation + 0.5*move_vec + Vector3.UP*2, node.translation + move_vec, 0.5*dur,
		Tween.TRANS_CUBIC, Tween.EASE_IN,
		0.5*dur)
	tw.start()

func play_prescale_tween(tw, node, dur, scaling_down):
	var start_scale = Vector3.ONE
	var end_scale = 0.5*start_scale
	if not scaling_down:
		var temp = end_scale
		end_scale = start_scale
		start_scale = temp
	
	tw.interpolate_property(node, "scale",
		start_scale, end_scale, dur,
		Tween.TRANS_LINEAR, Tween.EASE_OUT)
	tw.start()

func get_correct_tween(map):
	var tween_used = map.tween
	if drag: tween_used = map.parallel_tween
	return tween_used
