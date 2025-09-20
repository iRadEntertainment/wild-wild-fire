@tool
extends Node3D
class_name CellsMng

enum MeshType {
	TILE,
	BASE,
	TREE_DEAD,
	TREE_BURNT,
}

var meshes = {
	MeshType.TILE:
		{
			"mesh": preload("res://assets/models/meshes/cell_top.mesh"),
			#"material": preload("res://assets/materials/cell_sand.material")
		},
	MeshType.BASE:
		{
			"mesh": preload("res://assets/models/meshes/cell_bot.mesh"),
			#"material": preload("res://assets/materials/cell_sand.material")
		},
	MeshType.TREE_DEAD:
		{
			"mesh": preload("res://assets/models/meshes/DeadTree.mesh"),
			#"material": preload("res://assets/materials/cell_sand.material")
		},
	MeshType.TREE_BURNT:
		{
			"mesh": preload("res://assets/models/meshes/BurntTree.mesh"),
			#"material": preload("res://assets/materials/cell_sand.material")
		},
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
	
	var inst_tile: MultiMeshInstance3D = meshes[MeshType.TILE]["instance"]
	var inst_base: MultiMeshInstance3D = meshes[MeshType.BASE]["instance"]
	#var inst_tree_dead: MultiMeshInstance3D = meshes[MeshType.TREE_DEAD]["instance"]
	#var inst_tree_burnt: MultiMeshInstance3D = meshes[MeshType.TREE_BURNT]["instance"]
	
	for x in map_data.size.x:
		for y in map_data.size.y:
			var grid_pos: Vector2i = Vector2i(x, y)
			var idx: int = y * map_data.size.x + x
			
			#top
			var top_transf: Transform3D = Transform3D.IDENTITY
			top_transf.origin = map_data.grid_pos_to_map_pos(grid_pos)
			top_transf.origin.y = map_data.get_elevation_at_grid_pos(grid_pos)
			inst_tile.multimesh.set_instance_transform(idx, top_transf)
			#multi_mesh_instance_3d.multimesh.set_instance_color(idx, Color(1,1,1,0.6))
			
			#bot
			var y_scale: float = top_transf.origin.y + 5 #m
			var bot_transf: Transform3D = top_transf.scaled_local(Vector3(1, y_scale, 1))
			inst_base.multimesh.set_instance_transform(idx, bot_transf)


func clear() -> void:
	for child in get_children():
		if child is MultiMeshInstance3D:
			child.free()


func create_multimesh_nodes() -> void:
	_instance_count = map.size.x * map.size.y
	
	for key: int in meshes:
		var mesh: Mesh = meshes[key]["mesh"] # remember to add the correct material
		var new_mesh_instance := MultiMeshInstance3D.new()
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
