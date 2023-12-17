extends MeshInstance

export(bool) var sides = true
export(float) var split = 0

var vertices = null

var scale_fac : float = 1.0005

func split_vertices():
	if split != 0:
		var tmp = []
		for v in vertices:
			tmp.append( v )
		vertices = []
		for i in range( 0, len( tmp ) / 2 ):
			var a = tmp[i*2]
			var b = tmp[i*2 + 1]
			var mid = b - a
			vertices.append( a )
			vertices.append( a + mid * split )
			vertices.append( b )
			vertices.append( b - mid * split )

func cube_create():
	
	vertices = []
	# top
	vertices.append( Vector3( -1, -1, -1 )*scale_fac )
	vertices.append( Vector3( 1, -1, -1 )*scale_fac )
	vertices.append( Vector3( 1, -1, -1 )*scale_fac )
	vertices.append( Vector3( 1, -1, 1 )*scale_fac )
	vertices.append( Vector3( 1, -1, 1 )*scale_fac )
	vertices.append( Vector3( -1, -1, 1 )*scale_fac )
	vertices.append( Vector3( -1, -1, 1 )*scale_fac )
	vertices.append( Vector3( -1, -1, -1 )*scale_fac )
	# bottom
	vertices.append( Vector3( -1, 1, -1 )*scale_fac )
	vertices.append( Vector3( 1, 1, -1 )*scale_fac )
	vertices.append( Vector3( 1, 1, -1 )*scale_fac )
	vertices.append( Vector3( 1, 1, 1 )*scale_fac )
	vertices.append( Vector3( 1, 1, 1 )*scale_fac )
	vertices.append( Vector3( -1, 1, 1 )*scale_fac )
	vertices.append( Vector3( -1, 1, 1 )*scale_fac )
	vertices.append( Vector3( -1, 1, -1 )*scale_fac )
	
	if sides:
		vertices.append( Vector3( -1, -1, -1 )*scale_fac )
		vertices.append( Vector3( -1, 1, -1 )*scale_fac )
		vertices.append( Vector3( 1, -1, -1 )*scale_fac )
		vertices.append( Vector3( 1, 1, -1 )*scale_fac )
		vertices.append( Vector3( 1, -1, 1 )*scale_fac )
		vertices.append( Vector3( 1, 1, 1 )*scale_fac )
		vertices.append( Vector3( -1, -1, 1 )*scale_fac )
		vertices.append( Vector3( -1, 1, 1 )*scale_fac )
	
	split_vertices()
	
	var _mesh = Mesh.new()
	var _surf = SurfaceTool.new()
	
	_surf.begin(Mesh.PRIMITIVE_LINES)
	for v in vertices:
		_surf.add_vertex(v)
	_surf.index()
	_surf.commit( _mesh )
	set_mesh( _mesh )
	
	vertices = null
	

func _ready():
	cube_create()

