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



var level_n: int
@onready var t_start: int = Time.get_ticks_msec()

var is_setup: bool = false

@warning_ignore_start("unused_signal")
signal setup_complete
signal game_lost
signal game_won


func _ready() -> void:
	propagate_call("setup", [], false)
	Aud.play_radio_voice("res://assets/sfx/voice_test_01_runaway_clear.ogg")


func setup() -> void:
	is_setup = true
	setup_complete.emit()
