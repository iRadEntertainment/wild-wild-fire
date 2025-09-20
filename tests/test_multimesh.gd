@tool
extends Node3D

@onready var mesh_top: MultiMeshInstance3D = $mesh_top
@onready var mesh_bot: MultiMeshInstance3D = $mesh_bot
@onready var mesh_decor: MultiMeshInstance3D = $mesh_decor


@export var map_data: MapData
