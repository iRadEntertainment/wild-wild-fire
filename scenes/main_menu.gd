extends Control


func _ready() -> void:
	get_tree().paused = false
	%pnl_settings.pnl_closed.connect(_on_pnl_closed)
	%pnl_credits.pnl_closed.connect(_on_pnl_closed)
	%tab.hide()


func _on_btn_start_pressed() -> void:
	Mng.start_game(1)


func _on_btn_settings_pressed() -> void:
	if %pnl_settings.is_visible_in_tree():
		%tab.hide()
	else:
		%tab.show()
		%pnl_settings.show()


func _on_btn_leaderboard_pressed() -> void:
	print_rich("[color=yellow]Leaderboard not implemented yet.")


func _on_btn_credits_pressed() -> void:
	if %pnl_credits.is_visible_in_tree():
		%tab.hide()
	else:
		%tab.show()
		%pnl_credits.show()


func _on_btn_quit_pressed() -> void:
	Mng.quit()


func _on_pnl_closed() -> void:
	%tab.hide()
