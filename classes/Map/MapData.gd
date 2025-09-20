@tool
extends Resource
class_name MapData

@warning_ignore("unused_private_class_variable")
@export_tool_button("Save to File", "Save") var _btn_save: Callable = save_to_file.bind("res://assets/map/map_data.res")


@export_group("Globals")
@export var size: Vector2i = Vector2i(256, 256) # px / cells
@export var cell_world_dim: float = 1.0


@export_group("Inputs", "in_")
@export_subgroup("Morphology")
@export var in_img_elevation: Image
@export_range(5.0, 50.0, 0.01) var in_elevation_scale: float = 20.0 #m
@export var in_min_max_elevation: Vector2
@export var in_tex_elevation_mask: Texture2D
@export_range(0.0, 1.0, 0.001) var in_water_level_ratio: float = 0.05

@export_subgroup("Decorations")
@export var in_tex_trees: Texture2D
@export var in_tex_buildings: Texture2D


@export_group("Output", "out_")
@export var out_map_world_center: Vector3
@export var out_img_elevation: Image
@export var out_img_elevation_mask: Image


#region Update
func update_outputs() -> void:
	_update_out_map_world_center()
	_update_out_img_elevation()
	_update_out_img_elevation_mask()


func _update_out_map_world_center() -> void:
	var temp: Vector2 = Vector2(size) / 2.0
	out_map_world_center = Vector3(temp.x, 0.0, temp.y) * cell_world_dim


func _update_out_img_elevation() -> void:
	if not in_img_elevation:
		out_img_elevation = null
		return
	
	var im_img_resized: Image = in_img_elevation.duplicate()
	im_img_resized.resize(size.x, size.y, Image.INTERPOLATE_NEAREST)
	
	out_img_elevation = Image.create(size.x, size.y, false, Image.FORMAT_L8)
	for x in size.x:
		for y in size.y:
			var col: Color = im_img_resized.get_pixel(x, y)
			var raw_elev: float = MapUtl.terrarium_color_to_height_meters(col)
			var height: float = MapUtl.normalize(raw_elev, in_min_max_elevation.x, in_min_max_elevation.y)
			var bw_col: Color = Color(height, height, height, 1.0)
			out_img_elevation.set_pixel(x, y, bw_col)


func _update_out_img_elevation_mask() -> void:
	if in_tex_elevation_mask:
		out_img_elevation_mask = in_tex_elevation_mask.get_image().duplicate()
		out_img_elevation_mask.resize(size.x, size.y)
	else:
		out_img_elevation_mask = null
#endregion



#region Utilities
func get_elevation_at_grid_pos(grid_pos: Vector2i) -> float:
	if not out_img_elevation:
		return 0.0
	var col: Color = out_img_elevation.get_pixelv(grid_pos)
	var elev: float = col.r * in_elevation_scale
	
	if out_img_elevation_mask:
		var mult: float = out_img_elevation_mask.get_pixelv(grid_pos).r
		elev *= mult
	
	return elev


func grid_pos_to_map_pos(grid_pos: Vector2i) -> Vector3:
	var pos := Vector3(grid_pos.x, 0.0, grid_pos.y) * cell_world_dim
	return pos - out_map_world_center


func grid_pos_and_elevation_to_map_pos(grid_pos: Vector2i, elevation: float) -> Vector3:
	var pos = grid_pos_to_map_pos(grid_pos)
	pos.y = elevation
	return pos


func map_to_grid_pos(map_pos: Vector3) -> Vector2i:
	var off_pos: Vector3 = map_pos + out_map_world_center
	off_pos /= cell_world_dim
	@warning_ignore("narrowing_conversion")
	return Vector2i(off_pos.x, off_pos.z)
#endregion


#region Save/Load
func save_to_file(filepath: String) -> void:
	ResourceSaver.save(self, filepath)


static func load_from_file(file_path: String) -> MapData:
	return ResourceLoader.load(file_path, "MapData")
#endregion
