extends RigidBody3D
class_name WaterParticle


@export_range(0.0, 1.0, 0.001) var water_intensity = 0.1
@export_range(1.0, 10.0, 0.1) var splash_radius = 2.0


func _ready() -> void:
	$part_normal.emitting = !Mng.is_scawy
	$part_easteregg.emitting = Mng.is_scawy
	if Mng.is_scawy:
		Aud.play_music_easteregg()


func _on_body_entered(body: StaticBody3D) -> void:
	#print("Water hit: ", body.name)
	set_deferred(&"sleeping", true)
	$coll.set_deferred(&"disabled", true)
	
	var is_terrain: bool = body.collision_layer == 0b100
	if is_terrain:
		var hit_pos: Vector2i = Mng.map_data.map_to_grid_pos(global_position)
		var sim_pos: Vector2i = Vector2i(hit_pos.y, hit_pos.x)
		Mng.game.fire_simulation.SpreadMoistureOnRadius(sim_pos, splash_radius, water_intensity)
	
	$part_normal.emitting = false
	$part_easteregg.emitting = false
	await get_tree().create_timer(1).timeout
	queue_free()
