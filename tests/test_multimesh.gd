@tool
extends Node3D

@onready var mesh_top: MultiMeshInstance3D = $mesh_top
@onready var mesh_bot: MultiMeshInstance3D = $mesh_bot
@onready var mesh_decor: MultiMeshInstance3D = $mesh_decor


@warning_ignore("unused_private_class_variable")
@export_tool_button("Run test", "MultiMesh") var _bt_run: Callable = _run_test


@export var map_data: MapData
@export_range(0.0, 1.0, 0.001) var spawn_anim_ratio: float = 1.0: set = _set_anim_ratio
@export var spawn_gradient: GradientTexture2D = preload("res://assets/materials/radial_gradient_cells_spawn.tres")


func _ready() -> void:
	if Engine.is_editor_hint():
		pass
	else:
		_run_test()


func _run_test() -> void:
	if not map_data:
		print("Oh how surprising! You forgot to put some map data in me!")
		return
	
	var inst_num: int = map_data.size.x * map_data.size.y
	mesh_top.multimesh.visible_instance_count = inst_num
	mesh_bot.multimesh.visible_instance_count = inst_num
	mesh_decor.multimesh.visible_instance_count = 0
	for x in map_data.size.x:
		for y in map_data.size.y:
			var grid_pos: Vector2i = Vector2i(x, y)
			var idx: int = y * map_data.size.x + x
			
			#top
			var top_transf: Transform3D = Transform3D.IDENTITY
			top_transf.origin = map_data.grid_pos_to_map_pos(grid_pos)
			top_transf.origin.y = map_data.get_elevation_at_grid_pos(grid_pos)
			mesh_top.multimesh.set_instance_transform(idx, top_transf)
			#multi_mesh_instance_3d.multimesh.set_instance_color(idx, Color(1,1,1,0.6))
			
			#bot
			var y_scale: float = top_transf.origin.y + 5 #m
			var bot_transf: Transform3D = top_transf.scaled_local(Vector3(1, y_scale, 1))
			mesh_bot.multimesh.set_instance_transform(idx, bot_transf)
			


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if not event.is_pressed() or event.is_echo(): return
		if event.keycode == KEY_E:
			_run_test()


func _set_anim_ratio(val: float) -> void:
	spawn_anim_ratio = val
	var grad: Gradient = spawn_gradient.gradient
	if spawn_anim_ratio < 0.5:
		var ratio: float = spawn_anim_ratio * 2.0
		grad.offsets[0] = 0.0
		grad.offsets[1] = lerpf(0.0, 0.3, ratio)
		grad.offsets[2] = lerpf(0.0, 0.6, ratio)
		grad.offsets[3] = lerpf(0.0, 1.0, ratio)
	else:
		var ratio: float = (spawn_anim_ratio - 0.5) * 2.0
		grad.offsets[0] = lerpf(0.0, 1.0, ratio)
		grad.offsets[1] = lerpf(0.3, 1.0, ratio)
		grad.offsets[2] = lerpf(0.6, 1.0, ratio)
		grad.offsets[3] = 1.0
