extends Node


var bg_audio = preload("res://assets/audio/main_theme.mp3")
var bg_audio_player

var active_players = []

var audio_preload = {
	# UI
	"button": preload("res://assets/audio/ui_button_press.ogg"),
	"selection": preload("res://assets/audio/ui_selection_change.ogg"),
	
	# Player specific
	"player_move": [
		preload("res://assets/audio/player_move_v2.ogg"),
		preload("res://assets/audio/player_move_v2_2.ogg")
	],
	
	# Knobs
	"knob_turn": [
		preload("res://assets/audio/knob_turn_1.ogg"),
		preload("res://assets/audio/knob_turn_2.ogg"),
		preload("res://assets/audio/knob_turn_3.ogg"),
		preload("res://assets/audio/knob_turn_4.ogg"),
	],
	"loose_knob": preload("res://assets/audio/loose_knob.ogg"),
	
	# Specialties for specific wizards
	"magnet_attract": preload("res://assets/audio/magnet_attract.ogg"),
	"magnet_repel": preload("res://assets/audio/magnet_repel.ogg"),
	"rotate": preload("res://assets/audio/rotate.ogg"),
	
	"battery_down": preload("res://assets/audio/battery_down.ogg"),
	"battery_up": preload("res://assets/audio/battery_up.ogg"),
	"convert": preload("res://assets/audio/convert.ogg"),
	"destruct": preload("res://assets/audio/destruct.ogg"),
	"ghost": preload("res://assets/audio/ghost.ogg"),
	
	# Game state (game over, win, loss, etc.)
	"game_win": preload("res://assets/audio/game_win.ogg"),
	"game_loss": preload("res://assets/audio/game_loss.ogg"),
	
	# Stacking, number changing, core functionality
	"activate": preload("res://assets/audio/activate.ogg"),
	"add_stack": preload("res://assets/audio/add_stack.ogg"),
	"die": preload("res://assets/audio/die.ogg"),
	"invert": preload("res://assets/audio/invert.ogg"),
	"remove_stack": preload("res://assets/audio/remove_stack.ogg"),
	"revive": preload("res://assets/audio/revive.ogg"),
	
	
}

func _ready():
	create_background_stream()

func create_background_stream():
	bg_audio_player = AudioStreamPlayer.new()
	add_child(bg_audio_player)
	
	bg_audio_player.bus = "BG"
	bg_audio_player.stream = bg_audio
	bg_audio_player.play()
	
	bg_audio_player.pause_mode = Node.PAUSE_MODE_PROCESS

func pick_audio(key):
	var wanted_audio = audio_preload[key]
	if wanted_audio is Array: wanted_audio = wanted_audio[randi() % wanted_audio.size()]
	return wanted_audio

func create_audio_player(volume_alteration, bus : String = "FX", spatial : bool = false, destroy_when_done : bool = true):
	var audio_player
	
	if spatial:
		audio_player = AudioStreamPlayer3D.new()
		audio_player.unit_db = volume_alteration
	else:
		audio_player = AudioStreamPlayer.new()
		audio_player.volume_db = volume_alteration
	
	audio_player.bus = bus
	
	active_players.append(audio_player)
	
	if destroy_when_done:
		audio_player.connect("finished", self, "audio_player_done", [audio_player])
	#audio_player.pause_mode = Node.PAUSE_MODE_PROCESS
	
	return audio_player

func audio_player_done(which_one):
	active_players.erase(which_one)
	which_one.queue_free()

func play_static_sound(key, volume_alteration = 0, bus : String = "GUI"):
	if not audio_preload.has(key): return
	
	var audio_player = create_audio_player(volume_alteration, bus)

	add_child(audio_player)
	
	audio_player.stream = pick_audio(key)
	audio_player.pitch_scale = 1.0 + 0.02*(randf()-0.5)
	audio_player.play()
	
	return audio_player

func play_dynamic_sound(creator, key, volume_alteration = 0, bus : String = "FX", destroy_when_done : bool = true):
	if not audio_preload.has(key): return
	if not G.level_load_complete: return
	if G.undo_mode and active_players.size() > 0: return
	
	var audio_player = create_audio_player(volume_alteration, bus, true, destroy_when_done)
	
	var pos = null
	var max_dist = -1
	if audio_player is AudioStreamPlayer2D:
		max_dist = 2000
		pos = creator.get_global_position()
		audio_player.set_position(pos)
	else:
		max_dist = 40
		pos = creator.get_translation()
		audio_player.set_translation(pos)
		
		audio_player.unit_size = 10

	audio_player.max_distance = max_dist
	audio_player.pitch_scale = 1.0 + 0.02*(randf()-0.5)
	
	add_child(audio_player)
	
	audio_player.stream = pick_audio(key)
	audio_player.play()
	
	return audio_player
