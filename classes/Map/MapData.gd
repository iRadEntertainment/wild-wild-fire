@tool
extends Resource
class_name MapData


const LEVELS_FOLDER: String = "res://scenes/levels/"
const TEST_FILEPATH: String = "res://assets/map/map_data.res"
const MAP_LEGEND: Dictionary = {
	CellPreview.SoilType.GRASS: Color(0.197, 0.693, 0.0, 1.0),
	CellPreview.SoilType.SAND: Color(0.826, 0.637, 0.526, 1.0),
	CellPreview.SoilType.ROCK: Color(0.764, 0.799, 0.775, 1.0),
	CellPreview.SoilType.URBAN: Color(0.18, 0.322, 0.31, 1.0),
}


var level_folder: String:
	get:
		if not level_name: return ""
		return LEVELS_FOLDER + "level_%s/" % level_name

@export var level_name: String = ""
@warning_ignore_start("unused_private_class_variable")
@export_tool_button("Save to File", "Save") var _btn_save: Callable = save_to_file
@export_tool_button("Update Output", "Reload") var _btn_update: Callable = update_outputs
@export_tool_button("Export Drawing Img", "Image") var _btn_export: Callable = export_img
@warning_ignore_restore("unused_private_class_variable")


@export_group("Globals")
@export var rng_seed: String = ""
@export var size: Vector2i = Vector2i(256, 256) # px / cells
@export var cell_world_dim: float = 1.0
@export_range(0.0, 25.0, 0.5) var boundary_offset: float = 10.0


@export_group("Inputs", "in_")
@export_subgroup("Morphology")
@export var in_img_elevation: Image
@export_range(5.0, 50.0, 0.1) var in_max_elevation: float = 20.0 #m
@export var in_min_max_elevation: Vector2
@export var in_tex_elevation_mask: Texture2D
@export_range(0.0, 50.0, 0.1) var in_water_level: float = 2.0:
	set(val):
		in_water_level = val
		in_water_level_updated.emit(in_water_level)
signal in_water_level_updated(in_water_level: float)

@export_subgroup("Decorations")
@export var in_tex_tiles: Texture2D
@export var in_tex_dry: Texture2D
@export var in_tex_trees: Texture2D


@export_group("Output", "out_")
@export var out_map_world_center: Vector3

@export_subgroup("Morphology")
@export var out_img_elevation: Image
@export var out_img_elevation_mask: Image
@export var out_btm_water: BitMap

@export_subgroup("Tile Data")
@export var out_btm_tiles_grass: BitMap
@export var out_btm_tiles_sand: BitMap
@export var out_btm_tiles_rock: BitMap
@export var out_btm_tiles_urban: BitMap
@export var out_tiles_grass: Array[Vector2i]
@export var out_tiles_sand: Array[Vector2i]
@export var out_tiles_rock: Array[Vector2i]
@export var out_tiles_urban: Array[Vector2i]


var rng: RandomNumberGenerator


#region Update
func update_outputs() -> void:
	_update_rng()
	_update_out_map_world_center()
	_update_out_img_elevation_mask()
	_update_out_img_elevation()
	_update_tile_data()


func _update_rng() -> void:
	rng = RandomNumberGenerator.new()
	if rng_seed:
		rng.seed = hash(rng_seed)
	elif level_name:
		rng.seed = hash(level_name)


func _update_out_map_world_center() -> void:
	var temp: Vector2 = Vector2(size) / 2.0
	out_map_world_center = Vector3(temp.x, 0.0, temp.y) * cell_world_dim


func _update_out_img_elevation_mask() -> void:
	if in_tex_elevation_mask:
		out_img_elevation_mask = in_tex_elevation_mask.get_image().duplicate()
		out_img_elevation_mask.resize(size.x, size.y)
	else:
		out_img_elevation_mask = null


func _update_out_img_elevation() -> void:
	if not in_img_elevation:
		out_img_elevation = null
		return
	
	var im_img_resized: Image = in_img_elevation.duplicate()
	im_img_resized.resize(size.x, size.y, Image.INTERPOLATE_NEAREST)
	
	out_img_elevation = Image.create(size.x, size.y, false, Image.FORMAT_L8)
	var max_blend_height: float = 0.0
	for x in size.x:
		for y in size.y:
			var raw_col: Color = im_img_resized.get_pixel(x, y)
			var raw_elev: float = MapUtl.terrarium_color_to_height_meters(raw_col)
			var height: float = MapUtl.normalize(raw_elev, in_min_max_elevation.x, in_min_max_elevation.y)
			var height_blend: float = height
			if out_img_elevation_mask:
				var mask_height: float = out_img_elevation_mask.get_pixel(x, y).r
				height_blend *= mask_height
				max_blend_height = max(max_blend_height, height_blend)
			var bw_col: Color = Color(height_blend, height_blend, height_blend, 1.0)
			out_img_elevation.set_pixel(x, y, bw_col)
	
	# normalize, water Bitmap
	out_btm_water = BitMap.new()
	out_btm_water.resize(size)
	var water_level_ratio: float = in_water_level / in_max_elevation
	for x in size.x:
		for y in size.y:
			var blend_height: float = out_img_elevation.get_pixel(x, y).r
			var normalized_height: float = blend_height
			# normalize after blending with the mask
			if out_img_elevation_mask:
				normalized_height /= max_blend_height
				var bw_col: Color = Color(normalized_height, normalized_height, normalized_height, 1.0)
				out_img_elevation.set_pixel(x, y, bw_col)
			
			# water btm
			var is_water: bool = normalized_height <= water_level_ratio
			if is_water:
				out_btm_water.set_bit(x, y, true)


func _update_tile_data() -> void:
	if not in_tex_tiles: return
	if Vector2i(in_tex_tiles.get_size()) != size:
		push_warning("in_tex_tiles size is diffecent from map size")
		return
	var in_img_tiles: Image = in_tex_tiles.get_image()
	in_img_tiles.convert(Image.FORMAT_RGBA8)
	_reset_out_tiles()
	
	var col_grass: Color = MAP_LEGEND[CellPreview.SoilType.GRASS]
	var col_sand: Color = MAP_LEGEND[CellPreview.SoilType.SAND]
	var col_rock: Color = MAP_LEGEND[CellPreview.SoilType.ROCK]
	var col_urban: Color = MAP_LEGEND[CellPreview.SoilType.URBAN]
	
	for x in size.x:
		for y in size.y:
			var p: Vector2i = Vector2i(x, y)
			var sampled_col: Color = in_img_tiles.get_pixelv(p)
			
			if its_almost_the_same_color(sampled_col, col_grass):
				out_btm_tiles_grass.set_bitv(p, true)
				out_tiles_grass.append(p)
			elif its_almost_the_same_color(sampled_col, col_sand):
				out_btm_tiles_sand.set_bitv(p, true)
				out_tiles_sand.append(p)
			elif its_almost_the_same_color(sampled_col, col_rock):
				out_btm_tiles_rock.set_bitv(p, true)
				out_tiles_rock.append(p)
			elif its_almost_the_same_color(sampled_col, col_urban):
				out_btm_tiles_urban.set_bitv(p, true)
				out_tiles_urban.append(p)
			else:
				out_btm_tiles_sand.set_bitv(p, true)
				out_tiles_sand.append(p)


static func its_almost_the_same_color(col_a: Color, col_b: Color, lambda: float = 0.05) -> bool:
	var r: float = abs(col_a.r - col_b.r)
	var g: float = abs(col_a.g - col_b.g)
	var b: float = abs(col_a.b - col_b.b)
	var a: float = abs(col_a.a - col_b.a)
	return r < lambda and g < lambda and b < lambda and a < lambda


func _reset_out_tiles() -> void:
	out_btm_tiles_grass = BitMap.new()
	out_btm_tiles_grass.resize(size)
	out_btm_tiles_sand = BitMap.new()
	out_btm_tiles_sand.resize(size)
	out_btm_tiles_rock = BitMap.new()
	out_btm_tiles_rock.resize(size)
	out_btm_tiles_urban = BitMap.new()
	out_btm_tiles_urban.resize(size)
	out_tiles_grass = []
	out_tiles_sand = []
	out_tiles_rock = []
	out_tiles_urban = []

#endregion


func export_img() -> void:
	if not level_name:
		push_warning("Define a level name before export!")
		return
	update_outputs()
	
	# create elevation IMG.png
	var img_normal_map: Image = out_img_elevation.duplicate()
	img_normal_map.bump_map_to_normal_map(8.0)
	
	# apply water
	const WATER_COL: Color = Color.NAVY_BLUE
	for x in size.x:
		for y in size.y:
			var is_water: bool = out_btm_water.get_bit(x, y)
			if not is_water: continue
			#var water_col: Color = img_normal_map.get_pixel(x, y)
			#water_col.blend(WATER_COL)
			img_normal_map.set_pixel(x, y, WATER_COL)
	
	_make_level_dir()
	
	var img_filepath: String = level_folder + "level_%s_map.png" % level_name
	img_normal_map.save_png(img_filepath)
	
	var img_map_legend := Image.create(MAP_LEGEND.size(), 1, false, Image.FORMAT_RGBAF)
	for key: int in MAP_LEGEND.size():
		var col: Color = MAP_LEGEND[key]
		img_map_legend.set_pixel(key, 0, col)
	img_map_legend.resize(MAP_LEGEND.size() * 3, 3, Image.INTERPOLATE_NEAREST)
	var img_legend_filepath: String = level_folder + "level_%s_legend.png" % level_name
	img_map_legend.save_png(img_legend_filepath)


#region Utilities
func get_elevation_at_grid_pos(grid_pos: Vector2i) -> float:
	if not out_img_elevation:
		return 0.0
	var col: Color = out_img_elevation.get_pixelv(grid_pos)
	var elev: float = col.r * in_max_elevation
	
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
func save_to_file() -> void:
	var filepath: String = TEST_FILEPATH
	if level_name:
		filepath = level_folder + "level_%s_mapdata.tres" % level_name
		_make_level_dir()
	ResourceSaver.save(self, filepath)


static func load_from_file(file_path: String) -> MapData:
	return ResourceLoader.load(file_path, "MapData")


func _make_level_dir() -> void:
	var dir := DirAccess.open("res://")
	dir.make_dir_recursive(level_folder.trim_prefix("res://"))
#endregion
