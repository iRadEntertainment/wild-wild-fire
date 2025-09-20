extends PanelContainer


@export var in_main_menu: bool = false

signal pnl_closed


func _ready() -> void:
	%btn_quit.visible = not in_main_menu



func _on_btn_close_pressed() -> void:
	hide()
	pnl_closed.emit()
func _on_btn_quit_pressed() -> void:
	Mng.quit()
