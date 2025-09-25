@tool
extends Node3D
class_name CellsMng

enum MeshType {
	BASE,
	TILE_GRASS,
	TILE_SAND,
	TILE_ROCK,
	TILE_URBAN,
	#TREE_DEAD,
	#TREE_BURNT,
}

var meshes = {
	MeshType.BASE:
		{
			"mesh": preload("res://assets/models/meshes/cell_bot.mesh"),
			#"material": preload("res://assets/materials/cell_sand.material")
		},
	MeshType.TILE_GRASS:
		{
			"mesh": preload("res://assets/models/meshes/cell_top.mesh"),
			"material": preload("res://assets/materials/tiles/cell_grass.material")
		},
	MeshType.TILE_SAND:
		{
			"mesh": preload("res://assets/models/meshes/cell_top.mesh"),
			"material": preload("res://assets/materials/tiles/cell_sand.material")
		},
	MeshType.TILE_ROCK:
		{
			"mesh": preload("res://assets/models/meshes/cell_top.mesh"),
			"material": preload("res://assets/materials/tiles/cell_rock.material")
		},
	MeshType.TILE_URBAN:
		{
			"mesh": preload("res://assets/models/meshes/cell_top.mesh"),
			"material": preload("res://assets/materials/tiles/cell_urban.material")
		},
	#MeshType.TREE_DEAD:
		#{
			#"mesh": preload("res://assets/models/meshes/DeadTree.mesh"),
			##"material": preload("res://assets/materials/cell_sand.material")
		#},
	#MeshType.TREE_BURNT:
		#{
			#"mesh": preload("res://assets/models/meshes/BurntTree.mesh"),
			##"material": preload("res://assets/materials/cell_sand.material")
		#},
}


@export var map: Map
func set_map(_map: Map) -> void:
	map = _map
var map_data: MapData:
	get: return map.data

var _instance_count: int


#region Update

#endregion


#region Populate
func populate_multimesh() -> void:
	if not map: return
	if not map.data: return
	clear()
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


func clear() -> void:
	for child in get_children():
		if child is MultiMeshInstance3D:
			child.free()


func create_multimesh_nodes() -> void:
	_instance_count = map.size.x * map.size.y
	
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
		multi.instance_count = _instance_count
		
		
		new_mesh_instance.multimesh = multi
		add_child(new_mesh_instance)
		meshes[key]["instance"] = new_mesh_instance
		if Engine.is_editor_hint():
			new_mesh_instance.owner = owner
#endregion
