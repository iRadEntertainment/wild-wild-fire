# Singleton Mng
extends Node

var is_debug_mode: bool = true #TODO: before build switch to false

var game: Game
var game_stats: GameStats
var game_env: Environment = preload("res://assets/materials/game_env.tres")

enum EndGame {FIRE_ESTINGUISHED, PLANE_CRASHED, AIRPORT_DESTROYED}
var end_game: EndGame

# getters
var map: Map:
	get: return game.map if game else null
var map_data: MapData:
	get: return game.map.data if game else null
var airport: Airport:
	get: return game.airport if game else null
var airplane: Airplane:
	get: return game.airplane if game else null
var game_sun: DirectionalLight3D:
	get: return game.sun if game else null


# game modifier
var is_night: bool = false:
	set(val):
		is_night = val
		if game:
			game.set_day_night()
var play_level_cinematic: bool = false
var is_scawy: bool = false
var is_infinite_fuel: bool = false:
	set(val):
		is_infinite_fuel = val
		if airplane:
			airplane.ConsumeFuel = !val
			if is_infinite_fuel:
				airplane.CurrentFuel = airplane.settings.MaxFuel
var is_infinite_water: bool = false:
	set(val):
		is_infinite_water = val
		if airplane:
			airplane.ConsumeWater = !val
			if is_infinite_water:
				airplane.CurrentWater = airplane.settings.MaxWater


signal game_ready
signal level_setup_complete



func go_to_main_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func start_game(level_n: int) -> void:
	reset_stats()
	var level_path: String
	match level_n:
		1: level_path = "res://scenes/levels/level_sapri/level_sapri.tscn"
	
	if not level_path:
		push_error("Cannot find level N scene: %" % level_n)
		return
	
	get_tree().change_scene_to_file(level_path)
	await get_tree().tree_changed
	game = get_tree().current_scene
	if not game.is_node_ready(): await game.ready
	game_ready.emit()
	
	game_stats.new_level(game)
	if not game.is_setup: await game.setup_complete
	Aud.stop_music()
	level_setup_complete.emit()


func reset_stats() -> void:
	game_stats = GameStats.new()


func quit() -> void:
	get_tree().quit()
