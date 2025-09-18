@tool
extends MeshInstance3D


@warning_ignore("unused_private_class_variable")
@export_tool_button("Apply Caustic Texture", "Texture2DArray") var _bt_apply_caustic: Callable = _apply
@export var texture_caustics: Texture2D


func _apply() -> void:
	if !texture_caustics: return
	var mat: ShaderMaterial = get_surface_override_material(0)
	var imgs: Array[Image] = [texture_caustics.get_image()]
	var arr: Texture2DArray = Texture2DArray.new()
	arr.create_from_images(imgs)
	mat.set_shader_parameter("caustic_sampler", arr)
