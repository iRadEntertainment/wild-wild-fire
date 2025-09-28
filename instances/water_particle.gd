extends RigidBody3D
class_name WaterParticle


func _ready() -> void:
	Aud.play_music_easteregg()


func _on_body_entered(_body: Node) -> void:
	$part_easteregg.emitting = false
	await get_tree().create_timer(1).timeout
	queue_free()
