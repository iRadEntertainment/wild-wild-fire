# Singleton Mng
extends Node

var is_debug_mode: bool = true

var game: Game
var game_stats: GameStats
var cam: ThirdPersonCamera

# getters
var map: Map:
	get: return game.map if game else null
var map_data
#var airport: Airport:
	#get: return game.airport if game else null
#var aeroplane: Airplane:
	#get: return game.airplane if game else null

signal level_setup_complete


func go_to_main_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func start_game(level_n: int) -> void:
	reset_stats()
	var level_path: String
	match level_n:
		1: level_path = "res://scenes/levels/level1/level_1.tscn"
	
	if not level_path:
		push_error("Cannot find level N scene: %" % level_n)
		return
	
	get_tree().change_scene_to_file(level_path)
	await get_tree().tree_changed
	game = get_tree().current_scene
	game_stats.new_level(game)
	if not game.is_setup: await game.setup_complete
	level_setup_complete.emit()


func reset_stats() -> void:
	game_stats = GameStats.new()


func quit() -> void:
	get_tree().quit()
