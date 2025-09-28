extends RigidBody3D
class_name WaterParticle


func _ready() -> void:
	if Mng.is_scawy:
		Aud.play_music_easteregg()
		$part_easteregg.emitting = true


func _on_body_entered(_body: Node) -> void:
	if Mng.is_scawy:
		$part_easteregg.emitting = false
	await get_tree().create_timer(1).timeout
	queue_free()
