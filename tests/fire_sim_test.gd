extends Control


func _on_btn_snapshot_pressed() -> void:
	var tex: Texture2D = %FireSimulation.OutputTexture
	var img: Image = tex.get_image()
	img.save_png("res://tests/test_fire_sim_output.png")
