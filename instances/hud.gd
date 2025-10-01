extends Control
class_name HUD


@onready var hud: HUD = %HUD
@onready var pnl_in_game_menu: InGameMenu = %pnl_in_game_menu

@export_range(0.1, 3.0, 0.1) var fade_duration: float = 2.5

var airplane: Airplane:
	get: return Mng.airplane if is_instance_valid(Mng.airplane) else null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	%pnl_debug.hide()
	%lb_info.self_modulate.a = 0
	fade_in()


func setup() -> void:
	Mng.game.game_won.connect(_on_game_won)
	Mng.game.game_lost.connect(_on_game_lost)
	Mng.airplane.OutOfFuel.connect(_on_airplane_out_of_fuel)


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_pressed() and event.keycode == KEY_BACKSLASH and Mng.is_debug_mode:
			%pnl_debug.visible = !%pnl_debug.visible


func _process(_delta: float) -> void:
	if %lb_fps.visible:
		%lb_fps.text = "FPS %.1f" % Performance.get_monitor(Performance.TIME_FPS)
	
	if !airplane: return
	_update_fuel_and_water_status()
	
	if Mng.is_debug_mode:
		_update_airplane_info()


func _update_fuel_and_water_status() -> void:
	var fuel_ratio: float = airplane.CurrentFuel / airplane.settings.MaxFuel
	var water_ratio: float = airplane.CurrentWater / airplane.settings.MaxWater
	%progress_fuel.value = fuel_ratio
	%progress_water.value = water_ratio


func _on_game_won(_end_game: Mng.EndGame) -> void:
	await get_tree().create_timer(3.0).timeout
	fade_out()
	await _tw_fade.finished
	Mng.go_to_endscreen()


func _on_game_lost(_end_game: Mng.EndGame) -> void:
	await get_tree().create_timer(3.0).timeout
	fade_out()
	await _tw_fade.finished
	Mng.go_to_endscreen()


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


var _tw_fade: Tween
func fade_in() -> void:
	%fade_col.self_modulate.a = 1.0
	if _tw_fade:
		_tw_fade.kill()
	_tw_fade = create_tween()
	_tw_fade.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_tw_fade.tween_property(%fade_col, "self_modulate:a", 0.0, fade_duration)


func fade_out() -> void:
	if _tw_fade:
		_tw_fade.kill()
	_tw_fade = create_tween()
	_tw_fade.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_tw_fade.tween_property(%fade_col, "self_modulate:a", 1.0, fade_duration)


func give_instruction(text: String) -> void:
	%lb_info.text = text
	%anim_info.play(&"flash")


func _on_airplane_out_of_fuel() -> void:
	Aud.play_alarm()
