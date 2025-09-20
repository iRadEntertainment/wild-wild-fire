@tool
extends Node3D
class_name CellPreview

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

# initial properties
var cells_mng: CellsMng
@export var soil_type: SoilType = SoilType.GRASS: set = _set_soil_type
@export var top_type: TopType = TopType.TREES_LUSH: set = _set_top_type
var cell_id: Vector2i
var elevation: float
var moisture: float
var heat: float

#state
var is_burnt: bool
var is_burning: bool

# locals
var _tw_spawn_in: Tween
var spawn_y_offset: float = 50 # meters


#region Init
func _ready() -> void:
	update_cell_dimensions()
	update_soil_type()
	update_top_type()
	#_animate_spawn()
#endregion


func _animate_spawn() -> void:
	var final_pos_y: float = position.y
	
	position.y += spawn_y_offset
	
	if _tw_spawn_in:
		_tw_spawn_in.kill()
	
	_tw_spawn_in = create_tween()
	_tw_spawn_in.set_ease(Tween.EASE_OUT)
	_tw_spawn_in.set_trans(Tween.TRANS_BOUNCE)
	_tw_spawn_in.tween_property(self, "position:y", final_pos_y, 0.6)


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
