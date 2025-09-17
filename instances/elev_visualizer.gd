@tool
extends MeshInstance3D


@export var map: Map
@export var fetcher: MapElevationFetcher: set = _set_fetcher

#region Preview Fields
@export_subgroup("Preview")
@export var texture_albedo: Texture2D:
	set(val):
		texture_albedo = val
		if is_node_ready():
			mat.set_shader_parameter("texture_albedo", val)
@export var texture_heightmap: Texture2D:
	set(val):
		texture_heightmap = val
		if is_node_ready():
			mat.set_shader_parameter("texture_heightmap", val)
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

var plane: PlaneMesh:
	get: return mesh
var mat: ShaderMaterial:
	get: return plane.material


func _set_fetcher(_fetcher: MapElevationFetcher) -> void:
	fetcher = _fetcher
	if not fetcher:
		return
	
	if not fetcher.heightmap_fetched.is_connected(_update):
		fetcher.heightmap_fetched.connect(_update)
	if not fetcher.satellite_fetched.is_connected(_update):
		fetcher.satellite_fetched.connect(_update)
	
	_update()


func _update() -> void:
	# texture
	if fetcher:
		if fetcher.img_elevation:
			texture_albedo = ImageTexture.create_from_image(fetcher.img_satellite)
			texture_heightmap = ImageTexture.create_from_image(fetcher.img_elevation)
			#center_meters = -fetcher.min_height
	
	# dimensions
	plane.size = map.data.size
	
	#position
	position.x = plane.size.x/2.0
	position.z = plane.size.y/2.0
