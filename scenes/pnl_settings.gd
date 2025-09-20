extends PanelContainer
class_name PnlSettings


signal pnl_closed

func _on_btn_close_pressed() -> void:
	hide()
	pnl_closed.emit()


func _on_btn_tab_graphics_pressed() -> void: %tab.current_tab = 0
func _on_btn_tab_audio_pressed() -> void: %tab.current_tab = 1
func _on_btn_tab_game_pressed() -> void: %tab.current_tab = 2
