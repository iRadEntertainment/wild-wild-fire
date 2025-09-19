@tool
extends Node3D
class_name CellsMng


@warning_ignore_start("unused_private_class_variable")
@export_tool_button("Respawn Cells", "Button") var _respawn_btn: Callable = respawn_cells
@export_tool_button("CLEAR", "Button") var _clear_btn: Callable = clear


@export var map: Map
func set_map(_map: Map) -> void:
	map = _map


# locals
var cells: Array[Cell] = []
var _tw_spawn: Tween


func respawn_cells() -> void:
	clear()
	if not map: return
	var map_center: Vector2i = map.size / 2
	var center_magnitude: float = map_center.length()
	#spawn_cell_at(map_center)
	
	var total_duration: float = 3.0 # sec
	if _tw_spawn:
		_tw_spawn.kill()
	_tw_spawn = create_tween()
	_tw_spawn.set_parallel()
	
	for x in map.size.x:
		for y in map.size.y:
			var grid_pos: Vector2i = Vector2i(x, y)
			var distance_from_center: float = (grid_pos - map_center).length()
			var ratio: float = 1.0 - ((center_magnitude - distance_from_center) / center_magnitude)
			var delay: float = total_duration * ratio
			_tw_spawn.tween_callback(spawn_cell_at.bind(grid_pos)).set_delay(delay)


func clear() -> void:
	for cell: Cell in get_children():
		cell.queue_free()
	cells.clear()


func spawn_cell_at(grid_pos: Vector2i) -> void:
	if not map: return
	if not map.data: return
	if not map.data.out_img_elevation: return
	
	var img_to_size_ratio: Vector2i = map.data.out_img_elevation.get_size() / map.size
	var sample_pos: Vector2i = grid_pos * img_to_size_ratio
	var sampled_col: Color = map.data.out_img_elevation.get_pixelv(sample_pos)
	var elevation: float = MapUtl.terrarium_color_to_height_meters(sampled_col)
	var elevation_scaled: float = elevation * map.data.elevation_scale
	
	var new_cell: Cell = preload("res://instances/cell.tscn").instantiate()
	new_cell.name = "Cell_%03d_%03d" % [grid_pos.x, grid_pos.y]
	new_cell.position = MapUtl.grid_to_world(grid_pos, elevation_scaled)
	new_cell.elevation = elevation_scaled
	new_cell.soil_type = Cell.SoilType.SAND if elevation < 5.0 else Cell.SoilType.GRASS
	add_child(new_cell)
	if Engine.is_editor_hint():
		new_cell.owner = owner
	cells.append(new_cell)
