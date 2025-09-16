@tool
extends MeshInstance3D


@export var map: Map
@export var fetcher: MapElevationFetcher: set = _set_fetcher



func _set_fetcher(_fetcher: MapElevationFetcher) -> void:
	fetcher = _fetcher
	if not fetcher:
		return
	
	if not fetcher.tile_fetched.is_connected(_update):
		fetcher.tile_fetched.connect(_update)
	
	_update()


func _update() -> void:
	var plane: PlaneMesh = mesh
	
	# texture
	var mat: ShaderMaterial = plane.material
	var tex: Texture2D = null
	if fetcher:
		if fetcher.result_texture:
			tex = fetcher.result_texture
	
	mat.set_shader_parameter("texture_albedo", tex)
	
	# dimensions
	if not map: return
	plane.size = map.settings.size
	
	#position
	position.x = plane.size.x/2.0
	position.z = plane.size.y/2.0
