@tool
extends Node3D
class_name Map



@warning_ignore_start("unused_private_class_variable")
#region Tools
@export_tool_button("Populate", "MultiMesh") var _btn_populate: Callable = _populate_multimesh
@export_tool_button("Clear tiles", "MultiMesh") var _btn_clear: Callable = _clear_multimesh
@export var data: MapData


@export_group("Fetch Elevation")
@export var coord_latitude: float = 39.87082
@export var coord_longitude: float = 15.78452
@export_range(0, 19, 1) var zoom: int = 13

@export_tool_button("Fetch elevation Image", "Button") var _fetch_now_btn: Callable = _fetch_now
func _fetch_now() -> void:
	if Engine.is_editor_hint():
		map_elevation_fetcher._fetch_tile(coord_latitude, coord_longitude, zoom)
@export var show_satellite: bool = false:
	set(val):
		show_satellite = val
		if not is_node_ready(): await ready
		%elev_visualizer.visible = show_satellite


@export_group("Animation")
@onready var spawn_gradient: GradientTexture2D = preload("res://assets/materials/radial_gradient_cells_spawn.tres")
@export_range(0.0, 1.0, 0.001) var spawn_anim_ratio: float = 1.0: set = _set_anim_ratio
#endregion


@onready var map_elevation_fetcher: MapElevationFetcher = %MapElevationFetcher
@onready var cells_mng: CellsMng = %cells_mng
@onready var water_mesh: MeshInstance3D = %water_mesh
#@onready var simulation: FireSimulation = FireSimulation.new()

var size: Vector2i:
	get:
		if not data: return Vector2i.ZERO
		return data.size


func _ready() -> void:
	# Editor tools
	if Engine.is_editor_hint():
		_connect_editor_signals()
		return
	
	propagate_call("set_map", [self])


#region Editor Tools
func _connect_editor_signals() -> void:
	if not map_elevation_fetcher.heightmap_fetched.is_connected(_update_elevation_heightmap):
		map_elevation_fetcher.heightmap_fetched.connect(_update_elevation_heightmap)


func _populate_multimesh() -> void:
	if not is_node_ready(): await ready
	if not data: return
	data.update_outputs()
	%cells_mng.populate_multimesh()
	%water_mesh.position.y = data.in_elevation_scale * data.in_water_level_ratio


func _clear_multimesh() -> void:
	if not is_node_ready(): await ready
	%cells_mng.clear()


func _update_elevation_heightmap() -> void:
	if !Engine.is_editor_hint(): return
	data.in_img_elevation = map_elevation_fetcher.img_elevation
	data.in_min_max_elevation = Vector2(map_elevation_fetcher.min_height, map_elevation_fetcher.max_height)


func _set_anim_ratio(val: float) -> void:
	spawn_anim_ratio = val
	if not is_node_ready(): await ready
	
	var grad: Gradient = spawn_gradient.gradient
	if spawn_anim_ratio < 0.5:
		var ratio: float = spawn_anim_ratio * 2.0
		grad.offsets[0] = 0.0
		grad.offsets[1] = lerpf(0.0, 0.3, ratio)
		grad.offsets[2] = lerpf(0.0, 0.6, ratio)
		grad.offsets[3] = lerpf(0.0, 1.0, ratio)
	else:
		var ratio: float = (spawn_anim_ratio - 0.5) * 2.0
		grad.offsets[0] = lerpf(0.0, 1.0, ratio)
		grad.offsets[1] = lerpf(0.3, 1.0, ratio)
		grad.offsets[2] = lerpf(0.6, 1.0, ratio)
		grad.offsets[3] = 1.0
#endregion
