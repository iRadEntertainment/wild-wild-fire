# intro.tscn
extends Control


var skip_delta: float = 0.0
const SKIP_TIME: float = 0.5


func _process(delta: float) -> void:
	if Input.is_action_pressed(&"ui_cancel"):
		skip_delta += delta
	elif skip_delta > 0.0:
		skip_delta -= delta
		skip_delta = min(0.0, skip_delta)
	
	%lb_skip_highlight.size.x = %lb_skip.size.x * (skip_delta/SKIP_TIME)
	
	if skip_delta > SKIP_TIME:
		skip()


func skip() -> void:
	Mng.go_to_main_menu()


#callback from the animation
func _on_intro_anim_finished() -> void:
	Mng.go_to_main_menu()
