extends Control
class_name HUD


@onready var hud: HUD = %HUD
@onready var pnl_in_game_menu: InGameMenu = %pnl_in_game_menu


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_pressed() and event.keycode == KEY_BACKSLASH:
			%pnl_debug.visible = !%pnl_debug.visible


func _process(_delta: float) -> void:
	if not %pnl_debug.visible: return
	var nfo: String
	nfo = "CurrentSpeed: %.03f" % Mng.airplane.CurrentSpeed
	nfo += "\nCurrentPitch: %.03f" % Mng.airplane.CurrentPitch
	nfo += "\nCurrentRoll: %.03f" % Mng.airplane.CurrentRoll
	nfo += "\nCurrentThrust: %.03f" % Mng.airplane.CurrentThrust
	nfo += "\nCurrentDirection: (%.02f, %.02f)" % [Mng.airplane.CurrentDirection.x, Mng.airplane.CurrentDirection.y]
	nfo += "\nIsBoosting: %s" % Mng.airplane.IsBoosting
	nfo += "\nIsTakingOff: %s" % Mng.airplane.IsTakingOff
	nfo += "\nIsLanding: %s" % Mng.airplane.IsLanding
	nfo += "\nIsLanded: %s" % Mng.airplane.IsLanded
	nfo += "\nElevFromSea: %.01f" % Mng.airplane.ElevFromSea
	nfo += "\nElevFromTerrain: %.01f" % Mng.airplane.ElevFromTerrain
	%lb_debug_info.text = nfo
