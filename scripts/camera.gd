extends Camera

var cam_offset : Vector3 = Vector3(0,7,3.6) #Vector3(0,7,1.5)
var zoom_factor : float = 1.0
onready var map = get_node("../Map")

const EDGE_MARGIN : float = 40.0

const BG_COLORS = [
	Color(46/255.0, 172/255.0, 205/255.0), # lightblue
	Color(235/255.0, 172/255.0, 98/255.0), # orange/beige
	Color(231/255.0, 101/255.0, 101/255.0), # red
	Color(206/255.0, 231/255.0, 101/255.0), # limegreen
	Color(114/255.0, 231/255.0, 101/255.0), # turqoise green
	Color(146/255.0, 146/255.0, 246/255.0), # purple
	Color(231/255.0, 145/255.0, 246/255.0) # pink
] 

func activate():
	environment = environment.duplicate(true)
	environment.background_color = choose_random_bg_color()

func choose_random_bg_color():
	return BG_COLORS[randi() % BG_COLORS.size()]

func _physics_process(dt):
	center_on_map(dt)
	change_camera_angle(dt)

func change_camera_angle(dt):
	if Input.is_action_pressed("camera_to_top") or Input.get_action_strength("camera_to_top") > 0.5:
		cam_offset = cam_offset.rotated(Vector3.RIGHT, dt)
	elif Input.is_action_pressed("camera_to_side") or Input.get_action_strength("camera_to_side") > 0.5:
		cam_offset = cam_offset.rotated(Vector3.RIGHT, -dt)
	
	cam_offset.y = clamp(cam_offset.y, 0.05, 20)
	cam_offset.z = clamp(cam_offset.z, 0.05, 20)

func center_on_map(dt):
	var top_left = Vector3.ZERO
	var block_size = (1.0 / GDict.grid_config.tile_size)
	var bottom_right = Vector3(map.data.width, 0, map.data.height)*block_size
	
	var avg = (top_left + bottom_right)*0.5
	var new_pos = avg + cam_offset*zoom_factor
	
	set_translation(lerp(get_translation(), new_pos, 5*dt))
	
	look_at(avg, Vector3.UP)
	
	var top_left_2d = unproject_position(top_left)
	var bottom_right_2d = unproject_position(bottom_right)
	var vp = get_viewport().size
	
	if top_left_2d.x < EDGE_MARGIN or top_left_2d.y < EDGE_MARGIN:
		zoom_factor += dt
	
	if bottom_right_2d.x > (vp.x - EDGE_MARGIN) or bottom_right_2d.y > (vp.y - EDGE_MARGIN):
		zoom_factor += dt
	
	#var interp_fac = 2.0
	#set_translation(lerp(get_translation(), new_pos, interp_fac*dt))
