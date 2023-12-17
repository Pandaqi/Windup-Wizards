class_name GameOver

var we_won : bool

func _init(w):
	we_won = w

func execute(map):
	var txt = "Game Over"
	if we_won: txt = "Congratulations!"
	map.UI.flash_world_title(txt)

	map.state.game_over_mode = true
	map.UI.move_buttons_for_game_over(we_won)
	map.game_over.change_overlay(true, we_won)
	
	yield(map.tween, "tween_all_completed")
	
	if we_won:
		GAudio.play_static_sound("game_win")
	else:
		GAudio.play_static_sound("game_loss")
	
	return false

func rollback(map):
	map.game_over.change_overlay(false, we_won)
	map.UI.unmove_buttons_for_game_over(we_won)
	map.state.game_over_mode = false
	
	yield(map.tween, "tween_all_completed")
	return false
