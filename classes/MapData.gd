@tool
extends Resource
class_name MapData

@warning_ignore("unused_private_class_variable")
@export_tool_button("Save to File", "Save") var _btn_save: Callable = save_to_file.bind("res://assets/map/map_data.res")


@export_group("Globals")
@export var size: Vector2i = Vector2i(256, 256): # px / cells
	set(val):
		size = val
		var temp: Vector2 = Vector2(size) / 2.0
		out_map_world_center = Vector3(temp.x, 0.0, temp.y) * cell_world_dim
		_update_out_img_elevation()
@export var cell_world_dim: float = 1.0: #m
	set(val):
		cell_world_dim = val
		var temp: Vector2 = Vector2(size) / 2.0
		out_map_world_center = Vector3(temp.x, 0.0, temp.y) * cell_world_dim


@export_group("Inputs", "in_")
@export var in_img_elevation: Image:
	set(val):
		in_img_elevation = val
		_update_out_img_elevation()
@export_range(-500.0, 500.0, 0.1) var in_elevation_scale: float = 25.0 #m
@export var in_min_max_elevation: Vector2
@export var in_tex_buildings: Texture2D


@export_group("Output", "out_")
@export var out_map_world_center: Vector3
@export var out_img_elevation: Image



func get_elevation_at_grid_pos(grid_pos: Vector2i) -> float:
	if not out_img_elevation:
		return 0.0
	var col: Color = out_img_elevation.get_pixelv(grid_pos)
	return col.r * in_elevation_scale


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


func save_to_file(filepath: String) -> void:
	ResourceSaver.save(self, filepath)


static func load_from_file(file_path: String) -> MapData:
	return ResourceLoader.load(file_path, "MapData")


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
