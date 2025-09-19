# intro.tscn
extends Control


func skip() -> void:
	Mng.go_to_main_menu()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		skip()
