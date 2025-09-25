@tool
extends Node3D
class_name CellsMng

enum MeshType {
	BASE,
	TILE_GRASS,
	TILE_SAND,
	TILE_ROCK,
	TILE_URBAN,
}

var meshes = {
	MeshType.BASE:
		{
			"mesh": preload("res://assets/models/meshes/cell_bot.mesh"),
			#"material": preload("res://assets/materials/cell_sand.material"),
			#"instance": null,
		},
	MeshType.TILE_GRASS:
		{
			"mesh": preload("res://assets/models/meshes/cell_top.mesh"),
			"material": preload("res://assets/materials/tiles/cell_grass.material"),
		},
	MeshType.TILE_SAND:
		{
			"mesh": preload("res://assets/models/meshes/cell_top.mesh"),
			"material": preload("res://assets/materials/tiles/cell_sand.material"),
		},
	MeshType.TILE_ROCK:
		{
			"mesh": preload("res://assets/models/meshes/cell_top.mesh"),
			"material": preload("res://assets/materials/tiles/cell_rock.material"),
		},
	MeshType.TILE_URBAN:
		{
			"mesh": preload("res://assets/models/meshes/cell_top.mesh"),
			"material": preload("res://assets/materials/tiles/cell_urban.material"),
		},
}

var mesh_buildings_folder: String = "res://assets/models/meshes/buildings/"
var meshes_buildings: Array[Mesh] = []
var meshinstances_building: Array[MultiMeshInstance3D] = []


@export var map: Map
func set_map(_map: Map) -> void:
	map = _map
var map_data: MapData:
	get: return map.data

var _max_instance_count: int



#region Populate
func populate_multimesh() -> void:
	if not map: return
	if not map.data: return
	clear()
	fetch_meshes_buildings()
	create_multimesh_nodes()
	
	var inst_base: MultiMeshInstance3D = meshes[MeshType.BASE]["instance"]
	#var inst_tree_dead: MultiMeshInstance3D = meshes[MeshType.TREE_DEAD]["instance"]
	#var inst_tree_burnt: MultiMeshInstance3D = meshes[MeshType.TREE_BURNT]["instance"]
	
	for x in map_data.size.x:
		for y in map_data.size.y:
			var grid_pos: Vector2i = Vector2i(x, y)
			var idx: int = y * map_data.size.x + x
			var transf: Transform3D = Transform3D.IDENTITY
			transf.origin = map_data.grid_pos_to_map_pos(grid_pos)
			transf.origin.y = map_data.get_elevation_at_grid_pos(grid_pos)
			var y_scale: float = transf.origin.y + 5 #m
			var bot_transf: Transform3D = transf.scaled_local(Vector3(1, y_scale, 1))
			inst_base.multimesh.set_instance_transform(idx, bot_transf)
	
	var inst_tile_grass: MultiMeshInstance3D = meshes[MeshType.TILE_GRASS]["instance"]
	inst_tile_grass.multimesh.visible_instance_count = map_data.out_tiles_grass.size()
	for idx: int in map_data.out_tiles_grass.size():
			var grid_pos: Vector2i = map_data.out_tiles_grass[idx]
			var transf: Transform3D = Transform3D.IDENTITY
			transf.origin = map_data.grid_pos_to_map_pos(grid_pos)
			transf.origin.y = map_data.get_elevation_at_grid_pos(grid_pos)
			inst_tile_grass.multimesh.set_instance_transform(idx, transf)
	
	var inst_tile_sand: MultiMeshInstance3D = meshes[MeshType.TILE_SAND]["instance"]
	inst_tile_sand.multimesh.visible_instance_count = map_data.out_tiles_sand.size()
	for idx: int in map_data.out_tiles_sand.size():
			var grid_pos: Vector2i = map_data.out_tiles_sand[idx]
			var transf: Transform3D = Transform3D.IDENTITY
			transf.origin = map_data.grid_pos_to_map_pos(grid_pos)
			transf.origin.y = map_data.get_elevation_at_grid_pos(grid_pos)
			inst_tile_sand.multimesh.set_instance_transform(idx, transf)
	
	var inst_tile_rock: MultiMeshInstance3D = meshes[MeshType.TILE_ROCK]["instance"]
	inst_tile_rock.multimesh.visible_instance_count = map_data.out_tiles_rock.size()
	for idx: int in map_data.out_tiles_rock.size():
			var grid_pos: Vector2i = map_data.out_tiles_rock[idx]
			var transf: Transform3D = Transform3D.IDENTITY
			transf.origin = map_data.grid_pos_to_map_pos(grid_pos)
			transf.origin.y = map_data.get_elevation_at_grid_pos(grid_pos)
			inst_tile_rock.multimesh.set_instance_transform(idx, transf)
	
	var inst_tile_urban: MultiMeshInstance3D = meshes[MeshType.TILE_URBAN]["instance"]
	inst_tile_urban.multimesh.visible_instance_count = map_data.out_tiles_urban.size()
	for idx: int in map_data.out_tiles_urban.size():
			var grid_pos: Vector2i = map_data.out_tiles_urban[idx]
			var transf: Transform3D = Transform3D.IDENTITY
			transf.origin = map_data.grid_pos_to_map_pos(grid_pos)
			transf.origin.y = map_data.get_elevation_at_grid_pos(grid_pos)
			inst_tile_urban.multimesh.set_instance_transform(idx, transf)
	
	
	var building_visible_num_array: Array[int] = []
	building_visible_num_array.resize(meshinstances_building.size())
	building_visible_num_array.fill(0)
	for idx: int in map_data.out_tiles_urban.size():
		var rand_idx: int = map_data.rng.randi_range(-5, meshinstances_building.size()-1)
		if rand_idx < 0: continue
		building_visible_num_array[rand_idx] += 1
		
		var grid_pos: Vector2i = map_data.out_tiles_urban[idx]
		var mm_instance: MultiMeshInstance3D = meshinstances_building[rand_idx]
		var transf: Transform3D = Transform3D.IDENTITY
		transf.origin = map_data.grid_pos_to_map_pos(grid_pos)
		transf.origin.y = map_data.get_elevation_at_grid_pos(grid_pos) + 0.25
		transf.origin.x += map_data.rng.randf_range(-0.25, 0.25)
		transf.origin.z += map_data.rng.randf_range(-0.25, 0.25)
		transf = transf.scaled_local(Vector3.ONE * 0.5)
		
		var local_mm_idx: int = building_visible_num_array[rand_idx]
		mm_instance.multimesh.set_instance_transform(local_mm_idx, transf)
	
	
	for i: int in meshinstances_building.size():
		var count: int = building_visible_num_array[i]
		var mm_instance: MultiMeshInstance3D = meshinstances_building[i]
		mm_instance.multimesh.visible_instance_count = count


func clear() -> void:
	for child in get_children():
		child.free()


func fetch_meshes_buildings() -> void:
	meshes_buildings.clear()
	var d = DirAccess.open(mesh_buildings_folder)
	var files: PackedStringArray = d.get_files()
	for file: String in files:
		var mesh: Mesh = load(mesh_buildings_folder + file)
		meshes_buildings.append(mesh)


func create_multimesh_nodes() -> void:
	_max_instance_count = map.size.x * map.size.y
	
	for key: int in meshes:
		var mesh: Mesh = meshes[key]["mesh"] # remember to add the correct material
		var new_mesh_instance := MultiMeshInstance3D.new()
		new_mesh_instance.name = "MM%s" % (str(MeshType.keys()[key]).capitalize())
		
		if meshes[key].has("material"):
			var material: Material = meshes[key]["material"]
			new_mesh_instance.material_override = material
		
		var multi := MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.mesh = mesh
		
		var instances_count: int
		match key:
			MeshType.BASE: instances_count = _max_instance_count
			MeshType.TILE_GRASS: instances_count = map_data.out_tiles_grass.size()
			MeshType.TILE_SAND: instances_count = map_data.out_tiles_sand.size()
			MeshType.TILE_ROCK: instances_count = map_data.out_tiles_rock.size()
			MeshType.TILE_URBAN: instances_count = map_data.out_tiles_urban.size()
		
		multi.instance_count = instances_count
		
		new_mesh_instance.multimesh = multi
		add_child(new_mesh_instance)
		meshes[key]["instance"] = new_mesh_instance
		if Engine.is_editor_hint():
			new_mesh_instance.owner = owner
	
	
	# buildings
	meshinstances_building.clear()
	@warning_ignore("integer_division")
	var _instance_count_buildings := int(floor(_max_instance_count/50))
	var building_container := Node3D.new()
	building_container.name = "buildings"
	add_child(building_container)
	building_container.owner = owner
	for i: int in meshes_buildings.size():
		var mesh: Mesh = meshes_buildings[i]
		var new_mesh_instance := MultiMeshInstance3D.new()
		new_mesh_instance.name = "MMBuilding%02d" % i
		
		var multi := MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.mesh = mesh
		multi.instance_count = _instance_count_buildings
		
		new_mesh_instance.multimesh = multi
		building_container.add_child(new_mesh_instance)
		meshinstances_building.append(new_mesh_instance)
		if Engine.is_editor_hint():
			new_mesh_instance.owner = owner
#endregion
