@tool
extends MeshInstance3D


@export var map: Map
@export var fetcher: MapElevationFetcher: set = _set_fetcher

#region Preview Fields
@export_range(0.1, 5000.0, 0.1) var meters_per_unit: float = 256.0:
	set(val):
		meters_per_unit = val
		if is_node_ready():
			mat.set_shader_parameter("meters_per_unit", val)
@export_range(0.1, 20.0, 0.01) var exaggeration: float = 6.5:
	set(val):
		exaggeration = val
		if is_node_ready():
			mat.set_shader_parameter("exaggeration", val)
@export_range(-40000.0, 40000.0, 0.1) var center_meters: float = -20000.0:
	set(val):
		center_meters = val
		if is_node_ready():
			mat.set_shader_parameter("center_meters", val)
#endregion


#region Textures
var texture_albedo: Texture2D:
	set(val):
		texture_albedo = val
		if is_node_ready():
			mat.set_shader_parameter("texture_albedo", val)
var texture_heightmap: Texture2D:
	set(val):
		texture_heightmap = val
		if is_node_ready():
			mat.set_shader_parameter("texture_heightmap", val)
#endregion


var plane: PlaneMesh:
	get: return mesh
var mat: ShaderMaterial:
	get: return plane.material


func _set_fetcher(_fetcher: MapElevationFetcher) -> void:
	fetcher = _fetcher
	if not fetcher:
		return
	
	if not fetcher.heightmap_fetched.is_connected(_update_heightmap):
		fetcher.heightmap_fetched.connect(_update_heightmap)
	if not fetcher.satellite_fetched.is_connected(_update_satellite):
		fetcher.satellite_fetched.connect(_update_satellite)
	
	_update_heightmap()
	_update_satellite()


func _update_heightmap() -> void:
	if not fetcher: return
	# texture
	if fetcher.img_elevation:
		texture_heightmap = ImageTexture.create_from_image(fetcher.img_elevation)
	# dimensions and position
	plane.size = map.data.size
	position.x = 0.0
	position.z = 0.0


func _update_satellite() -> void:
	if not fetcher: return
	if fetcher.img_satellite:
		texture_albedo = ImageTexture.create_from_image(fetcher.img_satellite)
