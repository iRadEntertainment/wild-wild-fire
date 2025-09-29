@tool
extends Resource
class_name MapData


#region Exports
@warning_ignore_start("unused_private_class_variable")
@export var level_name: String = ""
#@export_tool_button("Save to File", "Save") var _btn_save: Callable = save_to_file
@export_tool_button("Update Output", "Reload") var _btn_update: Callable = update_outputs
@export_tool_button("Export Drawing Img", "Image") var _btn_export: Callable = export_img
@export_tool_button("Populate Data", "BitMap") var _btn_populate: Callable = populate_data


@export_group("Globals")
@export var rng_seed: String = ""
@export var size: Vector2i = Vector2i(128, 128) # px / cells
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
@export var out_img_tiles: Image
@export var out_img_dry: Image
@export var out_img_trees: Image


@export var out_btm_tiles_grass: BitMap
@export var out_btm_tiles_sand: BitMap
@export var out_btm_tiles_rock: BitMap
@export var out_btm_tiles_urban: BitMap
@export var out_tiles_grass: PackedVector2Array
@export var out_tiles_sand: PackedVector2Array
@export var out_tiles_rock: PackedVector2Array
@export var out_tiles_urban: PackedVector2Array


@export_group("MeshData")
@export_tool_button("Fetch Trees", "MeshInstance2D") var _btn_fetch_t: Callable = fetch_meshes_trees
@export_tool_button("Fetch Buildings", "MeshInstance3D") var _btn_fetch_b: Callable = fetch_meshes_buildings

@export_file_path() var mesh_buildings_folder_name: String = "buildings"
var mesh_buildings_folder: String:
	get: return MESH_BASE_FOLDER.path_join(mesh_buildings_folder_name)

@export_file_path() var mesh_trees_folder_name: String = "trees"
var mesh_trees_folder: String:
	get: return MESH_BASE_FOLDER.path_join(mesh_trees_folder_name)

@export_file_path() var mesh_trees_dry_folder_name: String = "trees_dry"
var mesh_trees_dry_folder: String:
	get: return MESH_BASE_FOLDER.path_join(mesh_trees_dry_folder_name)

@export var roads_gen_points_count: int = 10
@export_range(0.0, 0.1, 0.01) var trees_gen_base_probability: float = 0.03

@export_subgroup("Definitions", "mesh_def_")
@export var mesh_def_buildings: Array[MeshDefinition] = []
@export var mesh_def_trees: Array[MeshDefinition] = []
@export var mesh_def_trees_dry: Array[MeshDefinition] = []
@export var mesh_def_road_straight: Mesh = preload("res://assets/models/meshes/road_straight.mesh")
@export var mesh_def_road_crossing: Mesh = preload("res://assets/models/meshes/road_crossing.mesh")

@export_subgroup("BitMaps", "out_btm_")
@export var out_btm_buildings: BitMap
@export var out_btm_trees: BitMap
@export var out_btm_roads: BitMap
@export var out_mesh_roads_h: PackedVector2Array
@export var out_mesh_roads_v: PackedVector2Array
@export var out_mesh_roads_cross: PackedVector2Array


@export_group("FireSim", "firesim_")
@export var firesim_starting_cell: Vector2i = Vector2i(64, 96)
@export var firesim_pre_sim_ticks: int = 800
@export_range(0.0, 1.0, 0.01) var firesim_average_moisture: float = 0.5

@export_subgroup("Output Textures", "out_firesim_")
@export var out_firesim_burnable: Texture2D
@export var out_firesim_int_moisture: Texture2D
@export var out_firesim_ext_moisture: Texture2D

@warning_ignore_restore("unused_private_class_variable")
#endregion


const MESH_BASE_FOLDER: String= "res://assets/models/meshes/"
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

var rng: RandomNumberGenerator


#region Update
func update_outputs() -> void:
	_update_rng()
	_update_out_map_world_center()
	_update_out_img_elevation_mask()
	_update_out_img_elevation()
	_update_out_img_game_tiles()


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


func _update_out_img_game_tiles() -> void:
	print_rich("[color=yellow][MapData] Updating images Tiles...[/color]")
	
	if in_tex_tiles:
		out_img_tiles = in_tex_tiles.get_image().duplicate()
		out_img_tiles.resize(size.x, size.y, Image.INTERPOLATE_NEAREST)
	else:
		out_img_tiles = null
	
	if in_tex_dry:
		out_img_dry = in_tex_dry.get_image().duplicate()
		out_img_dry.resize(size.x, size.y)
	else:
		out_img_dry = null
	
	if in_tex_trees:
		out_img_trees = in_tex_trees.get_image().duplicate()
		out_img_trees.resize(size.x, size.y)
	else:
		out_img_trees = null
#endregion


#region Popoluate Data
func populate_data() -> void:
	rng.seed = hash(rng_seed)
	# tiles
	_clear_mesh_definition_data()
	_populate_tile_data()
	_populate_roads_data()
	_populate_buildings_data()
	_populate_trees_data()
	
	# fire sim
	_prepare_firesim_out()


func _clear_mesh_definition_data() -> void:
	print_rich("[color=blue][MapData] Clear Mesh definitions data...[/color]")
	for def: MeshDefinition in (mesh_def_buildings + mesh_def_trees + mesh_def_trees_dry):
		def.positions.clear()
		def.mesh_tranforms.clear()
		def.instance_count = 0
		def.mm_instance = null


func _populate_tile_data() -> void:
	print_rich("[color=yellow][MapData] Populationg Tile data...[/color]")
	_reset_out_tiles()
	if not out_img_tiles: return
	if out_img_tiles.get_size() != size:
		push_warning("out_img_tiles size is different from map size")
		return
	
	
	var col_grass: Color = MAP_LEGEND[CellPreview.SoilType.GRASS]
	var col_sand: Color = MAP_LEGEND[CellPreview.SoilType.SAND]
	var col_rock: Color = MAP_LEGEND[CellPreview.SoilType.ROCK]
	var col_urban: Color = MAP_LEGEND[CellPreview.SoilType.URBAN]
	
	for x in size.x:
		for y in size.y:
			var p: Vector2i = Vector2i(x, y)
			var sampled_col: Color = out_img_tiles.get_pixelv(p)
			
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


func _populate_roads_data() -> void:
	print_rich("[color=white][MapData] Populationg Roads data...[/color]")
	out_mesh_roads_cross.clear()
	for i: int in roads_gen_points_count:
		var rand_idx: int = rng.randi_range(0, out_tiles_urban.size()-1)
		var rand_p: Vector2i = out_tiles_urban[rand_idx]
		var iter: int = 0
		while Vector2(rand_p) in out_mesh_roads_cross:
			rand_idx = rng.randi_range(0, out_tiles_urban.size()-1)
			rand_p = out_tiles_urban[rand_idx]
			iter += 1
			if iter > 100:
				print("dafuq?")
				break
		
		out_mesh_roads_cross.append(rand_p)
		out_btm_roads.set_bitv(rand_p, true)
	
	for start: Vector2i in out_mesh_roads_cross:
		for dir in [Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN]:
			var iter: int = 0
			var next: Vector2i = start + dir
			var is_horiz: bool = dir.x != 0
			while out_btm_tiles_urban.get_bitv(next):
				if not out_btm_roads.get_bitv(next):
					if is_horiz:
						out_mesh_roads_h.append(next)
					else:
						out_mesh_roads_v.append(next)
					out_btm_roads.set_bitv(next, true)
				
				next += dir
				iter += 1
				if iter > 100:
					print("dafuq?")
					break


func _populate_buildings_data() -> void:
	if not out_btm_tiles_urban: return
	print_rich("[color=cyan][MapData] Populationg Buildings data...[/color]")
	
	# get weights and clear points positions
	var weights := PackedFloat32Array()
	for def: MeshDefinition in mesh_def_buildings:
		weights.append(def.probability)
		def.positions.clear()
		def.instance_count = 0
	
	for grid_pos: Vector2i in out_tiles_urban:
		if out_btm_roads.get_bitv(grid_pos):
			continue
		out_btm_buildings.set_bitv(grid_pos, true)
		var rand: float = rng.randf()
		var def_idx: int = Utl.select_from_weights(weights, rand)
		var def: MeshDefinition = mesh_def_buildings[def_idx]
		def.positions.append(grid_pos)
		def.instance_count += 1
		var transf := Transform3D.IDENTITY
		transf.origin = grid_pos_to_map_pos(grid_pos)
		transf.origin.y = get_elevation_at_grid_pos(grid_pos) + 0.25
		#transf.origin.x += rng.randf_range(-0.25, 0.25)
		#transf.origin.z += rng.randf_range(-0.25, 0.25)
		transf = transf.rotated_local(Vector3.UP, PI/4 * rng.randi_range(0, 7))
		transf = transf.scaled_local(Vector3.ONE * 0.5)
		def.mesh_tranforms.append(transf)


func _populate_trees_data() -> void:
	print_rich("[color=green][MapData] Populationg Trees data...[/color]")
	# get weights and clear points positions
	var weights_tree := PackedFloat32Array()
	for def: MeshDefinition in mesh_def_trees:
		weights_tree.append(def.probability)
		def.positions.clear()
		def.instance_count = 0
	
	var weights_tree_dry := PackedFloat32Array()
	for def: MeshDefinition in mesh_def_trees_dry:
		weights_tree_dry.append(def.probability)
		def.positions.clear()
		def.instance_count = 0
	
	
	for x in size.x:
		for y in size.y:
			var grid_pos := Vector2i(x, y)
			if not out_btm_tiles_grass.get_bitv(grid_pos):
				continue
			
			var sampled_prob: float = out_img_trees.get_pixelv(grid_pos).r
			sampled_prob *= 1.0 - trees_gen_base_probability
			var spawn_prob: float = trees_gen_base_probability + sampled_prob
			var is_spawn: bool = spawn_prob > rng.randf()
			if not is_spawn:
				continue
			out_btm_trees.set_bitv(grid_pos, true)
			
			var rand: float = rng.randf()
			var dryness: float = out_img_dry.get_pixelv(grid_pos).r
			var is_dry: bool = dryness > (0.2 * rand)
			
			var def_idx: int = Utl.select_from_weights(weights_tree, rand)
			var def: MeshDefinition = mesh_def_trees[def_idx]
			if not is_dry:
				def_idx = Utl.select_from_weights(weights_tree, rand)
				def = mesh_def_trees[def_idx]
			else:
				def_idx = Utl.select_from_weights(weights_tree_dry, rand)
				def = mesh_def_trees_dry[def_idx]
			
			def.positions.append(grid_pos)
			def.instance_count += 1
			var transf := Transform3D.IDENTITY
			transf.origin = grid_pos_to_map_pos(grid_pos)
			transf.origin.y = get_elevation_at_grid_pos(grid_pos) + 0.25
			transf = transf.rotated_local(Vector3.UP, rng.randf_range(-PI, PI))
			#transf.origin.x += rng.randf_range(-0.25, 0.25)
			#transf.origin.z += rng.randf_range(-0.25, 0.25)
			transf = transf.scaled_local(Vector3(1.0, rng.randf_range(0.8, 1.2), 1.0) )
			def.mesh_tranforms.append(transf)
	


func _reset_out_tiles() -> void:
	print_rich("[color=orange][MapData] Resetting Tiles data...[/color]")
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
	
	out_btm_buildings = BitMap.new()
	out_btm_buildings.resize(size)
	out_btm_trees = BitMap.new()
	out_btm_trees.resize(size)
	out_btm_roads = BitMap.new()
	out_btm_roads.resize(size)
	out_mesh_roads_h.clear()
	out_mesh_roads_v.clear()
	out_mesh_roads_cross.clear()


func _prepare_firesim_out() -> void:
	var img_burnable := Image.create(size.x, size.y, false, Image.FORMAT_L8)
	var img_int_moisture := Image.create(size.x, size.y, false, Image.FORMAT_L8)
	var img_ext_moisture := Image.create(size.x, size.y, false, Image.FORMAT_L8)
	
	for x in size.x:
		for y in size.y:
			var grid_pos := Vector2i(x, y)
			var is_sand: bool = out_btm_tiles_sand.get_bitv(grid_pos)
			var is_rock: bool = out_btm_tiles_rock.get_bitv(grid_pos)
			var is_water: bool = out_btm_water.get_bitv(grid_pos)
			if is_sand or is_rock or is_water: continue
			
			var is_tree: bool = out_btm_trees.get_bitv(grid_pos)
			var is_building: bool = out_btm_buildings.get_bitv(grid_pos)
			var is_grass: bool = out_btm_tiles_grass.get_bitv(grid_pos) and not is_tree
			var is_road: bool = out_btm_roads.get_bitv(grid_pos)
			
			var wetness: float = 1.0 - out_img_dry.get_pixelv(grid_pos).r * firesim_average_moisture
			var burnable_value: float
			var int_moist_value: float
			var ext_moist_value: float
			
			if is_tree:
				burnable_value = 0.8
				int_moist_value = 1.0 * wetness
				ext_moist_value = 0.0
			elif is_building:
				burnable_value = 1.0
				int_moist_value = 0.5 * wetness
				ext_moist_value = 0.0
			elif is_grass:
				burnable_value = 0.7
				int_moist_value = 0.2 * wetness
				ext_moist_value = 0.05
			elif is_road:
				burnable_value = 0.6
				int_moist_value = 0.1 * wetness
				ext_moist_value = 0.2
			
			var col_burnable := Color.WHITE * burnable_value
			var col_int_moist := Color.WHITE * int_moist_value
			var col_ext_moist := Color.WHITE * ext_moist_value
			img_burnable.set_pixelv(grid_pos, col_burnable)
			img_int_moisture.set_pixelv(grid_pos, col_int_moist)
			img_ext_moisture.set_pixelv(grid_pos, col_ext_moist)
	
	out_firesim_burnable = ImageTexture.create_from_image(img_burnable)
	out_firesim_int_moisture = ImageTexture.create_from_image(img_int_moisture)
	out_firesim_ext_moisture = ImageTexture.create_from_image(img_ext_moisture)
#endregion


#region MeshData
func fetch_meshes_trees() -> void:
	mesh_def_trees = []
	var d = DirAccess.open(mesh_trees_folder)
	var files: PackedStringArray = d.get_files()
	for file: String in files:
		var def := MeshDefinition.new()
		def.filename = file
		def.mesh = load(mesh_trees_folder.path_join(file))
		def.probability = 1.0
		mesh_def_trees.append(def)
	
	fetch_meshes_trees_dry()


func fetch_meshes_trees_dry() -> void:
	mesh_def_trees_dry = []
	var d = DirAccess.open(mesh_trees_dry_folder)
	var files = d.get_files()
	for file: String in files:
		var def := MeshDefinition.new()
		def.filename = file
		def.mesh = load(mesh_trees_dry_folder.path_join(file))
		def.probability = 1.0
		mesh_def_trees_dry.append(def)


func fetch_meshes_buildings() -> void:
	mesh_def_buildings = []
	var d = DirAccess.open(mesh_buildings_folder)
	var files: PackedStringArray = d.get_files()
	for file: String in files:
		var def := MeshDefinition.new()
		def.filename = file
		def.mesh = load(mesh_buildings_folder.path_join(file))
		def.probability = 1.0
		mesh_def_buildings.append(def)
#endregion


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


static func its_almost_the_same_color(col_a: Color, col_b: Color, lambda: float = 0.05) -> bool:
	var r: float = abs(col_a.r - col_b.r)
	var g: float = abs(col_a.g - col_b.g)
	var b: float = abs(col_a.b - col_b.b)
	var a: float = abs(col_a.a - col_b.a)
	return r < lambda and g < lambda and b < lambda and a < lambda
#endregion


#region Save/Load
#func save_to_file() -> void:
	#var filepath: String = TEST_FILEPATH
	#if level_name:
		#filepath = level_folder + "level_%s_mapdata.tres" % level_name
		#_make_level_dir()
	#ResourceSaver.save(self, filepath)


#static func load_from_file(file_path: String) -> MapData:
	#return ResourceLoader.load(file_path, "MapData")


func _make_level_dir() -> void:
	var dir := DirAccess.open("res://")
	dir.make_dir_recursive(level_folder.trim_prefix("res://"))
#endregion
