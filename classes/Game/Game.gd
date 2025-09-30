@tool
extends Node3D
class_name Game


@onready var gui: GUI = %GUI
@onready var map: Map = %map
@onready var fire_simulation: FireSimulation = %FireSimulation
@onready var airplane: Airplane = %Airplane
@onready var airport: Airport = %Airport
@onready var MarkerMapCam: Marker3D = %MarkerMapCam
@onready var marker_fire_start: Marker3D = %MarkerFireStart
@onready var sun: DirectionalLight3D = %sun
@onready var cam: GameCamera = %cam



var level_n: int
@onready var t_start: int = Time.get_ticks_msec()

enum CamType { FIXED, FOLLOW, BOTTOM, MAP, AIRPORT, FIRE, CINEMATIC }
var cam_type: CamType = CamType.FIXED: set = set_cam


var is_setup: bool = false
var is_simulation_running: bool = false

@warning_ignore_start("unused_signal")
signal setup_complete

signal simulation_started
signal simulation_paused
signal simulation_ended

var is_game_won: bool = false
var is_game_lost: bool = false
signal game_lost(endgame: Mng.EndGame)
signal game_won(endgame: Mng.EndGame)



func _ready() -> void:
	if Engine.is_editor_hint(): return
	propagate_call("setup", [], false)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if map.data.firesim_starting_cell == Vector2i.ZERO:
		map.data.firesim_starting_cell = map.data.map_to_grid_pos(marker_fire_start.global_position)
	marker_fire_start.global_position.y = map.data.get_elevation_at_grid_pos(map.data.firesim_starting_cell)
	
	
	cam.FirePosition = marker_fire_start.global_position
	cam.MapCenterTarget = Vector3() + Vector3.UP * map.data.get_elevation_at_grid_pos(Vector2i())
	set_cam_cinematic(marker_fire_start, 15.0)
	
	start_simulation()
	if Mng.play_level_cinematic or not Mng.is_debug_mode:
		_play_intro_cinematic()
	else:
		cam_type = CamType.FOLLOW
		airplane.CanInput = true


func _play_intro_cinematic() -> void:
	cam_type = CamType.CINEMATIC
	var aud_spotted: String = [
		"res://assets/voices/voice_fire reported on the island..wav",
		"res://assets/voices/voice_fire spotted on island..wav"
	].pick_random()
	Aud.play_radio_voice(aud_spotted)
	await Aud.voice_over
	await get_tree().create_timer(1.5).timeout
	
	cam_type = CamType.FOLLOW
	Aud.play_radio_voice("res://assets/voices/voice_Runway One, cleared for takeoff..wav")
	await Aud.voice_over
	airplane.CanInput = true
	gui.hud.give_instruction("Start thrusters (SHIFT up - CTRL down)")
	
	await airplane.TakeOff
	await get_tree().create_timer(3.0).timeout
	Aud.play_radio_voice("res://assets/voices/voice_proceed to the sea for a water scoop. Maintain low approach, scoop water, then return to the fire line..wav")


func setup() -> void:
	set_day_night()
	#map.data.update_outputs()
	#map.data.populate_data()
	Mng.end_game = -1
	
	airplane.CollidedWithTerrain.connect(_on_airplane_collision)
	airplane.FuelWarning.connect(_on_airplane_fuel_warning)
	airplane.WaterWarning.connect(_on_airplane_water_warning)
	airplane.ConsumeFuel = !Mng.is_infinite_fuel
	airplane.ConsumeWater = !Mng.is_infinite_water
	
	is_setup = true
	setup_complete.emit()


func start_simulation() -> void:
	fire_simulation.simSpeed = 200
	fire_simulation.InitTexturedMap(
		map.data.out_firesim_burnable,
		map.data.out_firesim_int_moisture,
		map.data.out_firesim_ext_moisture,
		Vector2i(map.data.firesim_starting_cell.y, map.data.firesim_starting_cell.x),
		map.data.firesim_pre_sim_ticks
	)
	fire_simulation.simSpeed = 2
	var next_pass_mat: ShaderMaterial = preload("res://assets/materials/next_pass.material")
	next_pass_mat.set_shader_parameter(&"firesim_output", fire_simulation.OutputTexture)
	next_pass_mat.set_shader_parameter(&"fire_img_size", fire_simulation.OutputTexture.get_size())
	is_simulation_running = true
	simulation_started.emit()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint(): return
	if fire_simulation.IsFireOut() and not is_game_won:
		is_game_won = true
		Mng.end_game = Mng.EndGame.FIRE_ESTINGUISHED
		game_won.emit(Mng.EndGame.FIRE_ESTINGUISHED)
		fire_simulation.process_mode = Node.PROCESS_MODE_DISABLED
		Aud.play_radio_voice("res://assets/voices/voice_fire extinguished. Mission complete, you’re cleared RTB..wav")
		set_process(false)
	
	if airplane.IsOnWater and airplane.IsOutOfFuel and Mng.end_game != Mng.EndGame.PLANE_ON_SEA:
		Mng.end_game = Mng.EndGame.PLANE_ON_SEA
		game_lost.emit(Mng.EndGame.PLANE_ON_SEA)


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		match event.keycode:
			KEY_1: cam_type = CamType.FIXED
			KEY_2: cam_type = CamType.FOLLOW
			KEY_3: cam_type = CamType.BOTTOM
			KEY_4: cam_type = CamType.MAP
			KEY_5: cam_type = CamType.AIRPORT
			KEY_6: cam_type = CamType.FIRE


func set_cam(type: CamType) -> void:
	cam_type = type
	cam.SetCamera(type as int)


func set_cam_cinematic(target: Node3D, distance: float) -> void:
	cam.SetCameraCinematic(target, distance)


func set_day_night() -> void:
	var env: Environment
	if Mng.is_night:
		env = load("res://assets/materials/game_env_night.tres")
	else:
		env = load("res://assets/materials/game_env.tres")
	%env.environment = env
	%sun.visible = !Mng.is_night
	%moon.visible = Mng.is_night


func _on_airplane_collision() -> void:
	var expl_inst: Node3D = preload("res://instances/explosion.tscn").instantiate()
	expl_inst.position = airplane.global_position
	add_child(expl_inst)
	set_cam_cinematic(expl_inst, 6)
	cam_type = CamType.CINEMATIC
	airplane.queue_free()
	var voices = [
		"res://assets/voices/voice_DAR 877 2.wav",
		"res://assets/voices/voice_DAR 877.wav",
		"res://assets/voices/voice_DELTA ALPHA ROMEA 877 v2.wav",
		"res://assets/voices/voice_DELTA ALPHA ROMEO 877.wav",
	]
	await get_tree().create_timer(1.0).timeout
	Aud.play_radio_voice(voices.pick_random())
	await Aud.voice_over
	await get_tree().create_timer(1.0).timeout
	Aud.play_radio_voice(voices.pick_random())
	await Aud.voice_over
	Aud.play_radio_voice(voices.pick_random())
	await Aud.voice_over
	await get_tree().create_timer(1.0).timeout
	Mng.end_game = Mng.EndGame.PLANE_CRASHED
	game_lost.emit(Mng.EndGame.PLANE_CRASHED)


func _on_airplane_fuel_warning() -> void:
	var voices = [
		"res://assets/voices/voice_monitor your fuel status. #2.wav",
		"res://assets/voices/voice_monitor your fuel status..wav",
		"res://assets/voices/voice_you’re low on fuel. Break off and return to the tanker base to refuel, then report back. #2 .wav",
		"res://assets/voices/voice_you’re low on fuel. Break off and return to the tanker base to refuel, then report back..wav",
	]
	Aud.play_radio_voice(voices.pick_random())


func _on_airplane_water_warning() -> void:
	Aud.play_radio_voice("res://assets/voices/voice_you’re low on water. Break off and return to the sea for water pickup..wav")
