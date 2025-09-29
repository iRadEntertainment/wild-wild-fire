@tool
extends Node3D
class_name Map



@warning_ignore_start("unused_private_class_variable")
#region Tools
@export_tool_button("Populate", "MultiMesh") var _btn_populate: Callable = _populate_multimesh
@export_tool_button("Clear tiles", "MultiMesh") var _btn_clear: Callable = _clear_multimesh
@export var data: MapData:
	set(val):
		data = val
		if data:
			if not data.in_water_level_updated.is_connected(_on_water_level_updated):
				data.in_water_level_updated.connect(_on_water_level_updated)


@export_group("Fetch Elevation")
@export var coord_latitude: float = 39.87082
@export var coord_longitude: float = 15.78452
@export_range(0, 19, 1) var zoom: int = 13

@export_tool_button("Fetch elevation Image", "Button") var _fetch_now_btn: Callable = _fetch_now
func _fetch_now() -> void:
	if Engine.is_editor_hint():
		map_elevation_fetcher._fetch_tile(coord_latitude, coord_longitude, zoom)
#@export var show_satellite: bool = false:
	#set(val):
		#show_satellite = val
		#if not is_node_ready(): await ready
		#%elev_visualizer.visible = show_satellite


@export_group("Animation")
@onready var spawn_gradient: GradientTexture2D = preload("res://assets/materials/radial_gradient_cells_spawn.tres")
@export_range(0.0, 1.0, 0.001) var spawn_anim_ratio: float = 1.0: set = _set_anim_ratio
#endregion


var size: Vector2i:
	get:
		if not data: return Vector2i.ZERO
		return data.size


#region Build nodes
var cells_mng: CellsMng
var map_elevation_fetcher: MapElevationFetcher
var sea: StaticBody3D
var terrain_coll: CollisionShape3D
var boundary_n: CollisionShape3D
var boundary_e: CollisionShape3D
var boundary_s: CollisionShape3D
var boundary_w: CollisionShape3D
var boundary_top: CollisionShape3D


func _enter_tree() -> void:
	if get_child_count(true) == 0:
		build_subnodes()
	else:
		cells_mng = find_child("cells_mng")
		map_elevation_fetcher = find_child("MapElevationFetcher")
		sea = find_child("sea")
		terrain_coll = find_child("terrain_coll")
		boundary_n = find_child("boundary_n")
		boundary_e = find_child("boundary_e")
		boundary_s = find_child("boundary_s")
		boundary_w = find_child("boundary_w")
		boundary_top = find_child("boundary_top")


func build_subnodes() -> void:
	print("[MAP] building subnodes")
	
	map_elevation_fetcher = MapElevationFetcher.new()
	map_elevation_fetcher.name = "MapElevationFetcher"
	add_child(map_elevation_fetcher)
	map_elevation_fetcher.owner = get_parent()
	
	cells_mng = CellsMng.new()
	cells_mng.name = "cells_mng"
	cells_mng.map = self
	add_child(cells_mng)
	cells_mng.owner = get_parent()
	
	sea = preload("res://instances/sea.tscn").instantiate()
	sea.name = "sea"
	add_child(sea)
	sea.owner = get_parent()
	
	_add_static_terrain()
	_add_static_boundaries()


func _add_static_terrain() -> void:
	var static_t := StaticBody3D.new()
	static_t.name = "static_terrain"
	static_t.collision_layer = 0b00100
	static_t.collision_mask = 0b11000
	terrain_coll = CollisionShape3D.new()
	terrain_coll.name = "terrain_coll"
	terrain_coll.shape = HeightMapShape3D.new()
	static_t.add_child(terrain_coll)
	add_child(static_t)
	static_t.owner = get_parent()
	terrain_coll.owner = get_parent()


func _add_static_boundaries() -> void:
	var static_b := StaticBody3D.new()
	static_b.name = "static_boundaries"
	
	boundary_n = CollisionShape3D.new()
	boundary_n.name = "boundary_n"
	var n_shape := WorldBoundaryShape3D.new()
	n_shape.plane = Plane.PLANE_XY
	boundary_n.shape = n_shape
	static_b.add_child(boundary_n)
	
	boundary_e = CollisionShape3D.new()
	boundary_e.name = "boundary_e"
	var e_shape := WorldBoundaryShape3D.new()
	e_shape.plane = -Plane.PLANE_YZ
	boundary_e.shape = e_shape
	static_b.add_child(boundary_e)
	
	boundary_s = CollisionShape3D.new()
	boundary_s.name = "boundary_s"
	var s_shape := WorldBoundaryShape3D.new()
	s_shape.plane = -Plane.PLANE_XY
	boundary_s.shape = s_shape
	static_b.add_child(boundary_s)
	
	boundary_w = CollisionShape3D.new()
	boundary_w.name = "boundary_w"
	var w_shape := WorldBoundaryShape3D.new()
	w_shape.plane = Plane.PLANE_YZ
	boundary_w.shape = w_shape
	static_b.add_child(boundary_w)
	
	boundary_top = CollisionShape3D.new()
	boundary_top.name = "boundary_top"
	var top_shape := WorldBoundaryShape3D.new()
	top_shape.plane = -Plane.PLANE_XZ
	boundary_top.shape = top_shape
	static_b.add_child(boundary_top)
	
	add_child(static_b)
	static_b.owner = get_parent()
	boundary_n.owner = get_parent()
	boundary_e.owner = get_parent()
	boundary_s.owner = get_parent()
	boundary_w.owner = get_parent()
	boundary_top.owner = get_parent()
#endregion


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
	if not is_node_ready(): return
	if not data:
		push_warning("No data")
		return
	data.update_outputs()
	_update_multimesh()
	_update_heighmap_collision()
	_update_boundaries()


func _update_multimesh() -> void:
	cells_mng.populate_multimesh()


func _update_heighmap_collision() -> void:
	var heightmap_shape: HeightMapShape3D = terrain_coll.shape
	var heightmap_img_converted: Image = data.out_img_elevation.duplicate()
	heightmap_img_converted.convert(Image.FORMAT_RF)
	heightmap_shape.map_depth = size.x
	heightmap_shape.map_width = size.y
	heightmap_shape.update_map_data_from_image(heightmap_img_converted, 0.0, data.in_max_elevation)


func _update_boundaries() -> void:
	sea.position.y = data.in_water_level
	boundary_n.position.z = -(data.out_map_world_center.z + data.boundary_offset) * data.cell_world_dim
	boundary_e.position.x =  (data.out_map_world_center.x + data.boundary_offset) * data.cell_world_dim
	boundary_s.position.z =  (data.out_map_world_center.z + data.boundary_offset) * data.cell_world_dim
	boundary_w.position.x = -(data.out_map_world_center.x + data.boundary_offset) * data.cell_world_dim
	boundary_top.position.y = (data.in_max_elevation + data.boundary_offset) * data.cell_world_dim


func _clear_multimesh() -> void:
	if not is_node_ready(): await ready
	cells_mng.clear()


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


func _on_water_level_updated(water_level_meters: float) -> void:
	sea.position.y = water_level_meters
