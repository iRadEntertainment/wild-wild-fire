extends CanvasLayer
class_name GUI

@onready var pnl_in_game_menu: InGameMenu = $pnl_in_game_menu


func _ready() -> void:
	%HUD.show()
	%pnl_in_game_menu.hide()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_tree().paused = !get_tree().paused
		%pnl_in_game_menu.visible = get_tree().paused
