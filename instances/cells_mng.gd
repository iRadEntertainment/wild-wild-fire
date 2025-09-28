@tool
extends Node3D
class_name CellsMng

enum TileType {
	BASE,
	TILE_GRASS,
	TILE_SAND,
	TILE_ROCK,
	TILE_URBAN,
}

const next_pass_material: Material = preload("res://assets/materials/next_pass.material")

var meshes = {
	TileType.BASE:
		{
			"mesh": preload("res://assets/models/meshes/cell_bot.mesh"),
			#"material": preload("res://assets/materials/cell_sand.material"),
			#"instance": null,
		},
	TileType.TILE_GRASS:
		{
			"mesh": preload("res://assets/models/meshes/cell_top.mesh"),
			"material": preload("res://assets/materials/tiles/cell_grass.material"),
		},
	TileType.TILE_SAND:
		{
			"mesh": preload("res://assets/models/meshes/cell_top.mesh"),
			"material": preload("res://assets/materials/tiles/cell_sand.material"),
		},
	TileType.TILE_ROCK:
		{
			"mesh": preload("res://assets/models/meshes/cell_top.mesh"),
			"material": preload("res://assets/materials/tiles/cell_rock.material"),
		},
	TileType.TILE_URBAN:
		{
			"mesh": preload("res://assets/models/meshes/cell_top.mesh"),
			"material": preload("res://assets/materials/tiles/cell_urban.material"),
		},
}

var meshinstances_roads: Array[MultiMeshInstance3D] = []
var building_container: Node3D
var tree_container: Node3D


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
	create_tiles_multimesh_nodes()
	update_base_tiles()
	update_tiles()
	update_roads()
	update_buildings()
	update_trees()
	update_trees_dry()


func update_base_tiles() -> void:
	var inst_base: MultiMeshInstance3D = meshes[TileType.BASE]["instance"]
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


func update_tiles() -> void:
	var inst_tile_grass: MultiMeshInstance3D = meshes[TileType.TILE_GRASS]["instance"]
	inst_tile_grass.multimesh.visible_instance_count = map_data.out_tiles_grass.size()
	for idx: int in map_data.out_tiles_grass.size():
		var grid_pos: Vector2i = map_data.out_tiles_grass[idx]
		var transf: Transform3D = Transform3D.IDENTITY
		transf.origin = map_data.grid_pos_to_map_pos(grid_pos)
		transf.origin.y = map_data.get_elevation_at_grid_pos(grid_pos)
		inst_tile_grass.multimesh.set_instance_transform(idx, transf)
		inst_tile_grass.multimesh.set_instance_custom_data(idx, Color(grid_pos.x, grid_pos.y,0,0))
	
	var inst_tile_sand: MultiMeshInstance3D = meshes[TileType.TILE_SAND]["instance"]
	inst_tile_sand.multimesh.visible_instance_count = map_data.out_tiles_sand.size()
	for idx: int in map_data.out_tiles_sand.size():
		var grid_pos: Vector2i = map_data.out_tiles_sand[idx]
		var transf: Transform3D = Transform3D.IDENTITY
		transf.origin = map_data.grid_pos_to_map_pos(grid_pos)
		transf.origin.y = map_data.get_elevation_at_grid_pos(grid_pos)
		inst_tile_sand.multimesh.set_instance_transform(idx, transf)
		inst_tile_sand.multimesh.set_instance_custom_data(idx, Color(grid_pos.x, grid_pos.y,0,0))
	
	var inst_tile_rock: MultiMeshInstance3D = meshes[TileType.TILE_ROCK]["instance"]
	inst_tile_rock.multimesh.visible_instance_count = map_data.out_tiles_rock.size()
	for idx: int in map_data.out_tiles_rock.size():
		var grid_pos: Vector2i = map_data.out_tiles_rock[idx]
		var transf: Transform3D = Transform3D.IDENTITY
		transf.origin = map_data.grid_pos_to_map_pos(grid_pos)
		transf.origin.y = map_data.get_elevation_at_grid_pos(grid_pos)
		inst_tile_rock.multimesh.set_instance_transform(idx, transf)
		inst_tile_rock.multimesh.set_instance_custom_data(idx, Color(grid_pos.x, grid_pos.y,0,0))
	
	var inst_tile_urban: MultiMeshInstance3D = meshes[TileType.TILE_URBAN]["instance"]
	inst_tile_urban.multimesh.visible_instance_count = map_data.out_tiles_urban.size()
	for idx: int in map_data.out_tiles_urban.size():
		var grid_pos: Vector2i = map_data.out_tiles_urban[idx]
		var transf: Transform3D = Transform3D.IDENTITY
		transf.origin = map_data.grid_pos_to_map_pos(grid_pos)
		transf.origin.y = map_data.get_elevation_at_grid_pos(grid_pos)
		inst_tile_urban.multimesh.set_instance_transform(idx, transf)
		inst_tile_urban.multimesh.set_instance_custom_data(idx, Color(grid_pos.x, grid_pos.y,0,0))


func update_roads() -> void:
	var mm_instance_road_cross: MultiMeshInstance3D = MultiMeshInstance3D.new()
	mm_instance_road_cross.name = "MMRoadCrossings"
	mm_instance_road_cross.material_overlay = next_pass_material
	var mm_instance_road := MultiMesh.new()
	mm_instance_road.transform_format = MultiMesh.TRANSFORM_3D
	mm_instance_road.use_custom_data = true
	mm_instance_road.mesh = map_data.mesh_def_road_crossing
	mm_instance_road.instance_count = map_data.out_mesh_roads_cross.size()
	
	for idx: int in map_data.out_mesh_roads_cross.size():
		var grid_pos: Vector2i = map_data.out_mesh_roads_cross[idx]
		var transf: Transform3D = Transform3D.IDENTITY
		transf.origin = map_data.grid_pos_to_map_pos(grid_pos)
		transf.origin.y = map_data.get_elevation_at_grid_pos(grid_pos) + 0.25
		mm_instance_road.set_instance_transform(idx, transf)
		mm_instance_road.set_instance_custom_data(idx, Color(grid_pos.x, grid_pos.y,0,0))
	mm_instance_road_cross.multimesh = mm_instance_road
	building_container.add_child(mm_instance_road_cross)
	mm_instance_road_cross.owner = owner
	
	var mm_instance_road_straight: MultiMeshInstance3D = MultiMeshInstance3D.new()
	mm_instance_road_straight.name = "MMRoadStraight"
	mm_instance_road_straight.material_overlay = next_pass_material
	
	var mm_instance_road_s := MultiMesh.new()
	mm_instance_road_s.transform_format = MultiMesh.TRANSFORM_3D
	mm_instance_road_s.use_custom_data = true
	mm_instance_road_s.mesh = map_data.mesh_def_road_straight
	mm_instance_road_s.instance_count = map_data.out_mesh_roads_h.size() + map_data.out_mesh_roads_v.size()
	
	var straight_idx: int = 0
	for i: int in map_data.out_mesh_roads_h.size():
		var grid_pos: Vector2i = map_data.out_mesh_roads_h[i]
		var transf: Transform3D = Transform3D.IDENTITY
		transf.origin = map_data.grid_pos_to_map_pos(grid_pos)
		transf.origin.y = map_data.get_elevation_at_grid_pos(grid_pos) + 0.25
		transf = transf.rotated_local(Vector3.UP, PI/2.0)
		mm_instance_road_s.set_instance_transform(straight_idx, transf)
		mm_instance_road_s.set_instance_custom_data(straight_idx, Color(grid_pos.x, grid_pos.y,0,0))
		straight_idx += 1
	for i: int in map_data.out_mesh_roads_v.size():
		var grid_pos: Vector2i = map_data.out_mesh_roads_v[i]
		var transf: Transform3D = Transform3D.IDENTITY
		transf.origin = map_data.grid_pos_to_map_pos(grid_pos)
		transf.origin.y = map_data.get_elevation_at_grid_pos(grid_pos) + 0.25
		mm_instance_road_s.set_instance_transform(straight_idx, transf)
		mm_instance_road_s.set_instance_custom_data(straight_idx, Color(grid_pos.x, grid_pos.y,0,0))
		straight_idx += 1
	
	mm_instance_road_straight.multimesh = mm_instance_road_s
	building_container.add_child(mm_instance_road_straight)
	mm_instance_road_straight.owner = owner


func update_buildings() -> void:
	for def: MeshDefinition in map_data.mesh_def_buildings:
		var mm_instance: MultiMeshInstance3D = def.mm_instance
		for idx: int in def.instance_count:
			var grid_pos: Vector2i = def.positions[idx]
			var transf: Transform3D = def.mesh_tranforms[idx]
			mm_instance.multimesh.set_instance_transform(idx, transf)
			mm_instance.multimesh.set_instance_custom_data(idx, Color(grid_pos.x, grid_pos.y,0,0))


func update_trees() -> void:
	for def: MeshDefinition in map_data.mesh_def_trees:
		var mm_instance: MultiMeshInstance3D = def.mm_instance
		for idx: int in def.instance_count:
			var grid_pos: Vector2i = def.positions[idx]
			var transf: Transform3D = def.mesh_tranforms[idx]
			mm_instance.multimesh.set_instance_transform(idx, transf)
			mm_instance.multimesh.set_instance_custom_data(idx, Color(grid_pos.x, grid_pos.y,0,0))


func update_trees_dry() -> void:
	for def: MeshDefinition in map_data.mesh_def_trees_dry:
		var mm_instance: MultiMeshInstance3D = def.mm_instance
		for idx: int in def.instance_count:
			var grid_pos: Vector2i = def.positions[idx]
			var transf: Transform3D = def.mesh_tranforms[idx]
			mm_instance.multimesh.set_instance_transform(idx, transf)
			mm_instance.multimesh.set_instance_custom_data(idx, Color(grid_pos.x, grid_pos.y,0,0))


func clear() -> void:
	for child in get_children():
		child.free()


func create_tiles_multimesh_nodes() -> void:
	_max_instance_count = map.size.x * map.size.y
	
	for key: int in meshes:
		var mesh: Mesh = meshes[key]["mesh"]
		var new_mesh_instance := MultiMeshInstance3D.new()
		new_mesh_instance.name = "MM%s" % (str(TileType.keys()[key]).capitalize())
		
		if meshes[key].has("material"):
			new_mesh_instance.material_override = meshes[key]["material"]
		if key in [TileType.TILE_GRASS, TileType.TILE_URBAN]:
			new_mesh_instance.material_overlay = next_pass_material
		
		var multi := MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.use_custom_data = true
		multi.mesh = mesh
		
		var instances_count: int
		match key:
			TileType.BASE: instances_count = _max_instance_count
			TileType.TILE_GRASS: instances_count = map_data.out_tiles_grass.size()
			TileType.TILE_SAND: instances_count = map_data.out_tiles_sand.size()
			TileType.TILE_ROCK: instances_count = map_data.out_tiles_rock.size()
			TileType.TILE_URBAN: instances_count = map_data.out_tiles_urban.size()
		
		multi.instance_count = instances_count
		
		new_mesh_instance.multimesh = multi
		add_child(new_mesh_instance)
		meshes[key]["instance"] = new_mesh_instance
		if Engine.is_editor_hint():
			new_mesh_instance.owner = owner
	
	
	# buildings
	building_container = Node3D.new()
	building_container.name = "buildings"
	add_child(building_container)
	building_container.owner = owner
	for def: MeshDefinition in map_data.mesh_def_buildings:
		var new_mesh_instance := MultiMeshInstance3D.new()
		new_mesh_instance.name = "M%s" % def.filename.get_basename()
		new_mesh_instance.material_overlay = next_pass_material
		var multi := MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.use_custom_data = true
		multi.mesh = def.mesh
		multi.instance_count = def.instance_count
		
		new_mesh_instance.multimesh = multi
		building_container.add_child(new_mesh_instance)
		def.mm_instance = new_mesh_instance
		if Engine.is_editor_hint():
			new_mesh_instance.owner = owner
	
	tree_container = Node3D.new()
	tree_container.name = "trees"
	add_child(tree_container)
	tree_container.owner = owner
	for def: MeshDefinition in map_data.mesh_def_trees:
		var new_mesh_instance := MultiMeshInstance3D.new()
		new_mesh_instance.name = "M%s" % def.filename.get_basename()
		new_mesh_instance.material_overlay = next_pass_material
		var multi := MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.use_custom_data = true
		multi.mesh = def.mesh
		multi.instance_count = def.instance_count
		
		new_mesh_instance.multimesh = multi
		tree_container.add_child(new_mesh_instance)
		def.mm_instance = new_mesh_instance
		if Engine.is_editor_hint():
			new_mesh_instance.owner = owner
	
	# dry trees
	for def: MeshDefinition in map_data.mesh_def_trees_dry:
		var new_mesh_instance := MultiMeshInstance3D.new()
		new_mesh_instance.name = "M%s" % def.filename.get_basename()
		new_mesh_instance.material_overlay = next_pass_material
		var multi := MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.use_custom_data = true
		multi.mesh = def.mesh
		multi.instance_count = def.instance_count
		
		new_mesh_instance.multimesh = multi
		tree_container.add_child(new_mesh_instance)
		def.mm_instance = new_mesh_instance
		if Engine.is_editor_hint():
			new_mesh_instance.owner = owner
#endregion
