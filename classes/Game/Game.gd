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

signal game_lost
signal game_won



func _ready() -> void:
	if Engine.is_editor_hint(): return
	propagate_call("setup", [], false)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func setup() -> void:
	is_setup = true
	setup_complete.emit()
	start_simulation.call_deferred()


func start_simulation() -> void:
	fire_simulation.InitTexturedMap(
		map.data.out_firesim_burnable,
		map.data.out_firesim_int_moisture,
		map.data.out_firesim_ext_moisture,
		map.data.firesim_starting_cell,
		100 #map.data.firesim_pre_sim_ticks
	)
	var next_pass_mat: ShaderMaterial = preload("res://assets/materials/next_pass.material")
	next_pass_mat.set_shader_parameter(&"firesim_output", fire_simulation.OutputTexture)
	is_simulation_running = true
	simulation_started.emit()
