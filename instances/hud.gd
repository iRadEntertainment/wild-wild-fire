extends Control
class_name HUD


@onready var hud: HUD = %HUD
@onready var pnl_in_game_menu: InGameMenu = %pnl_in_game_menu

var airplane: Airplane:
	get: return Mng.airplane


func _ready() -> void:
	%pnl_debug.hide()


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_pressed() and event.keycode == KEY_BACKSLASH and Mng.is_debug_mode:
			%pnl_debug.visible = !%pnl_debug.visible


func _process(_delta: float) -> void:
	_update_fuel_and_water_status()
	
	if Mng.is_debug_mode:
		_update_airplane_info()


func _update_fuel_and_water_status() -> void:
	var fuel_ratio: float = airplane.CurrentFuel / airplane.settings.MaxFuel
	var water_ratio: float = airplane.CurrentWater / airplane.settings.MaxWater
	%progress_fuel.value = fuel_ratio
	%progress_water.value = water_ratio


func _update_airplane_info() -> void:
	if not %pnl_debug.visible: return
	var nfo: String
	nfo = "CurrentSpeed: %.03f" % airplane.CurrentSpeed
	nfo += "\nCurrentPitch: %.03f" % airplane.CurrentPitch
	nfo += "\nCurrentRoll: %.03f" % airplane.CurrentRoll
	nfo += "\nCurrentThrust: %.03f" % airplane.CurrentThrust
	nfo += "\nCurrentDirection: (%.02f, %.02f)" % [airplane.CurrentDirection.x, airplane.CurrentDirection.y]
	nfo += "\nIsBoosting: %s" % airplane.IsBoosting
	nfo += "\nIsTakingOff: %s" % airplane.IsTakingOff
	nfo += "\nIsLanding: %s" % airplane.IsLanding
	nfo += "\nIsLanded: %s" % airplane.IsLanded
	nfo += "\nElevFromSea: %.01f" % airplane.ElevFromSea
	nfo += "\nElevFromTerrain: %.01f" % airplane.ElevFromTerrain
	%lb_debug_info.text = nfo
