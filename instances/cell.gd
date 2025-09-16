@tool
extends Node3D
class_name Cell

const MAT_CELL_GRASS := preload("res://assets/materials/cell_grass.material")
const MAT_CELL_ROCK := preload("res://assets/materials/cell_rock.material")
const MAT_CELL_SAND := preload("res://assets/materials/cell_sand.material")
const MAT_CELL_SIDE := preload("res://assets/materials/cell_side.material")


enum SoilType {
	GRASS,
	ROCK,
	SAND
}
enum TopType {
	TREES_LUSH,
}

@export var soil_type: SoilType = SoilType.GRASS: set = _set_soil_type
@export var top_type: TopType = TopType.TREES_LUSH: set = _set_top_type

var elevation: float
var moisture: float
var heat: float


#region Init
func _enter_tree() -> void:
	pass
#endregion


#region Updates
func update_cell_dimensions() -> void:
	$mesh_bot.scale.y = max(1.0, elevation)


func update_soil_type() -> void:
	var mat: StandardMaterial3D
	match soil_type:
		SoilType.GRASS: mat = MAT_CELL_GRASS
		SoilType.ROCK: mat = MAT_CELL_ROCK
		SoilType.SAND: mat = MAT_CELL_SAND
	$mesh_top.set_surface_override_material(0, mat)


func update_top_type() -> void:
	pass
#endregion


#region Setters
func _set_soil_type(val: SoilType) -> void:
	soil_type = val
	if not is_node_ready(): return
	update_soil_type()
func _set_top_type(val: TopType) -> void:
	top_type = val
	if not is_node_ready(): return
	update_top_type()
#endregion
