extends PanelContainer
class_name InGameMenu



func _ready() -> void:
	%pnl_settings.hide()
	%pnl_settings.visibility_changed.connect(_on_pnl_settings_visibility_changed)
	Aud.connect_all_buttons_sounds(self)


func _on_pnl_settings_visibility_changed() -> void:
	%vb_buttons.visible = !%pnl_settings.visible


#region Button Signals
func _on_btn_back_pressed() -> void:
	get_tree().paused = false
	hide()
func _on_btn_settings_pressed() -> void:
	%vb_buttons.hide()
	%pnl_settings.show()
func _on_btn_quit_to_main_pressed() -> void:
	Mng.go_to_main_menu()
func _on_btn_quit_pressed() -> void:
	Mng.quit()
#endregion
