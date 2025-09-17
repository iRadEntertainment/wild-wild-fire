@tool
extends Node3D
class_name Map


@onready var map_elevation_fetcher: MapElevationFetcher = %MapElevationFetcher
@export var data: MapData

var size: Vector2i:
	get:
		if not data: return Vector2i.ZERO
		return data.size


func _ready() -> void:
	# Editor tools
	if Engine.is_editor_hint():
		_connect_editor_signals()
		return
	
	propagate_call("set_map", [self])


#region Editor Tools
func _connect_editor_signals() -> void:
	if not map_elevation_fetcher.tile_fetched.is_connected(_update_elevation_map):
		map_elevation_fetcher.tile_fetched.connect(_update_elevation_map)


func _update_elevation_map() -> void:
	if !Engine.is_editor_hint(): return
	data.in_img_elevation = map_elevation_fetcher.img_elevation
	data.in_min_max_elevation = Vector2(map_elevation_fetcher.min_height, map_elevation_fetcher.max_height)
#endregion
