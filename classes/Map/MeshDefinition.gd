extends Resource
class_name MeshDefinition

# inputs
@export var filename: String
@export var mesh: Mesh
@export_range(0.0, 2.0, 0.1) var probability: float
@export var material: Material

# outputs
@export var instance_count: int # assigned by MapData
@export var positions: PackedVector2Array # assigned by MapData
@export var mesh_tranforms: Array[Transform3D] # assigned by MapData
var mm_instance: MultiMeshInstance3D = null # assigned by cells_mng to keep a reference to the node
