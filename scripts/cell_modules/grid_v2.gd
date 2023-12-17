extends MeshInstance

var def_color = Color(2/255.0, 40/255.0, 42/255.0)
var highlight_color = Color(1,0,0)
var support_color = Color(1,0,1)

var def_scale = 1.05
var highlight_scale = 1.08
var support_scale = 1.08

func _ready():
	material_override = material_override.duplicate(true)
	unhighlight()

func highlight():
	material_override.albedo_color = highlight_color
	scale = Vector3.ONE*highlight_scale

func unhighlight():
	material_override.albedo_color = def_color
	scale = Vector3.ONE*def_scale

func highlight_support():
	material_override.albedo_color = support_color
	scale = Vector3.ONE*support_scale

func unhighlight_support():
	material_override.albedo_color = def_color
	scale = Vector3.ONE*def_scale
