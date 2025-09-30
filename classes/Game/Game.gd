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
signal game_lost
signal game_won



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
	cam_type = CamType.CINEMATIC
	
	start_simulation()


func setup() -> void:
	is_setup = true
	airplane.ConsumeFuel = !Mng.is_infinite_fuel
	airplane.ConsumeWater = !Mng.is_infinite_water
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
		game_won.emit()
		set_process(false)


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
