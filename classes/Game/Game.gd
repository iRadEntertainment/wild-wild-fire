@tool
extends Node3D
class_name Game


@onready var gui: GUI = %GUI
@onready var map: Map = %map
@onready var fire_simulation: FireSimulation = %FireSimulation
@onready var airplane: Airplane = %Airplane
@onready var airport: Airport = %Airport
@onready var game_camera: GameCamera = %GameCamera
@onready var MarkerMapCam: Marker3D = %MarkerMapCam
@onready var sun: DirectionalLight3D = %sun


var level_n: int
@onready var t_start: int = Time.get_ticks_msec()

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


func setup() -> void:
	is_setup = true
	airplane.ConsumeFuel = !Mng.is_infinite_fuel
	airplane.ConsumeWater = !Mng.is_infinite_water
	setup_complete.emit()
	start_simulation()


func start_simulation() -> void:
	fire_simulation.simSpeed = 200
	fire_simulation.InitTexturedMap(
		map.data.out_firesim_burnable,
		map.data.out_firesim_int_moisture,
		map.data.out_firesim_ext_moisture,
		map.data.firesim_starting_cell,
		map.data.firesim_pre_sim_ticks
	)
	fire_simulation.simSpeed = 2
	var next_pass_mat: ShaderMaterial = preload("res://assets/materials/next_pass.material")
	next_pass_mat.set_shader_parameter(&"firesim_output", fire_simulation.OutputTexture)
	next_pass_mat.set_shader_parameter(&"fire_img_size", fire_simulation.OutputTexture.get_size())
	is_simulation_running = true
	simulation_started.emit()


func _process(_delta: float) -> void:
	if fire_simulation.IsFireOut() and not is_game_won:
		is_game_won = true
		game_won.emit()
		set_process(false)
