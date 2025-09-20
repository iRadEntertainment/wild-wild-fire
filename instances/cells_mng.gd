@tool
extends Node3D
class_name CellsMng


const MESHES = {
	"top": preload("res://assets/models/cell_top.mesh"),
	"bottom": preload("res://assets/models/cell_bot.mesh"),
	"trees_lush": preload("res://assets/models/cell_bot.mesh"),
	"trees_burnt": preload("res://assets/models/cell_bot.mesh"),
}


@export var map: Map
func set_map(_map: Map) -> void:
	map = _map
var map_data: MapData:
	get: return map.data


func populate_multimesh() -> void:
	if not map: return
	if not map.data: return
	
	var inst_num: int = map_data.size.x * map_data.size.y
	%mesh_top.multimesh.visible_instance_count = inst_num
	%mesh_bot.multimesh.visible_instance_count = inst_num
	%mesh_decor.multimesh.visible_instance_count = 0
	for x in map_data.size.x:
		for y in map_data.size.y:
			var grid_pos: Vector2i = Vector2i(x, y)
			var idx: int = y * map_data.size.x + x
			
			#top
			var top_transf: Transform3D = Transform3D.IDENTITY
			top_transf.origin = map_data.grid_pos_to_map_pos(grid_pos)
			top_transf.origin.y = map_data.get_elevation_at_grid_pos(grid_pos)
			%mesh_top.multimesh.set_instance_transform(idx, top_transf)
			#multi_mesh_instance_3d.multimesh.set_instance_color(idx, Color(1,1,1,0.6))
			
			#bot
			var y_scale: float = top_transf.origin.y + 5 #m
			var bot_transf: Transform3D = top_transf.scaled_local(Vector3(1, y_scale, 1))
			%mesh_bot.multimesh.set_instance_transform(idx, bot_transf)
