extends Control



func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	select_ending()


func select_ending() -> void:
	var title: String = ""
	var description: String = ""
	match Mng.end_game:
		Mng.EndGame.FIRE_ESTINGUISHED:
			title = "Plane Crashed!"
			description = ""
		Mng.EndGame.PLANE_CRASHED:
			title = "Plane Crashed!"
			description = ""
		Mng.EndGame.AIRPORT_DESTROYED:
			title = "Plane Crashed!"
			description = ""
	
	%lb_main.text = title
	%lb_description.text = description


func _on_btn_return_pressed() -> void: Mng.go_to_main_menu()
func _on_btn_credits_pressed() -> void: %pnl_credits.show()
func _on_btn_quit_pressed() -> void: Mng.quit()
