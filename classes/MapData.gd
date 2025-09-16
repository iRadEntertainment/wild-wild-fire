extends Resource
class_name MapData


@export var settings: MapSettings
@export var img_elevation: Image


var size: Vector2i:
	get: return settings.size
