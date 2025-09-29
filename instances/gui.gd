extends CanvasLayer
class_name GUI

@onready var pnl_in_game_menu: InGameMenu = $pnl_in_game_menu


func _ready() -> void:
	%HUD.show()
	%pnl_in_game_menu.hide()


func setup() -> void:
	Mng.game.game_won.connect(_on_game_won)
	Mng.game.game_lost.connect(_on_game_lost)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_tree().paused = !get_tree().paused
		%pnl_in_game_menu.visible = get_tree().paused


func _on_game_won() -> void: pass
func _on_game_lost() -> void: pass


func _process(_delta: float) -> void:
	%lb_fps.text = "FPS %.1f" % Performance.get_monitor(Performance.TIME_FPS)
