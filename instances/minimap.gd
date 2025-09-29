extends PanelContainer


var world_to_map_ratio: Vector2


func setup() -> void:
	Mng.game.simulation_started.connect(_on_game_simulation_started)
	world_to_map_ratio = %icons.size / (Vector2(Mng.map.size) * Mng.map_data.cell_world_dim)


func _process(_delta: float) -> void:
	var plane_world_pos: Vector2 = Vector2(Mng.airplane.global_position.x, Mng.airplane.global_position.z)
	plane_world_pos += Vector2(Mng.map.size)/2.0
	
	var plane_map_pos: Vector2 = plane_world_pos
	plane_map_pos *= %icons.size / Vector2(Mng.map.size)
	%airplane_ico.position = plane_map_pos
	%airplane_ico.rotation = -Mng.airplane.rotation.y# - PI/2.0


func assign_minimap_textures() -> void:
	%firesim_preview.texture = Mng.game.fire_simulation.OutputTexture
	%tex_heat.texture = Mng.game.fire_simulation.OutputTexture
	%tex_int_moist.texture = Mng.game.fire_simulation.OutputTexture
	%tex_water.texture = Mng.game.fire_simulation.OutputTexture
	%tex_burnt.texture = Mng.game.fire_simulation.OutputTexture


func _on_game_simulation_started() -> void:
	assign_minimap_textures()
