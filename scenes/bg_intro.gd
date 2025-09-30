extends TextureRect


@onready var ov1_init_pos: Vector2 = %bg_overlay1.position
@onready var ov2_init_pos: Vector2 = %bg_overlay2.position

func _process(_delta: float) -> void:
	var center: Vector2 = size/2
	var m_pos: Vector2 = get_global_mouse_position()
	var rate: Vector2 = (m_pos - center) / size
	
	var ov1_pos: Vector2 = ov1_init_pos * ( rate)
	#ov1_pos.y *= -1
	var ov2_pos: Vector2 = ov2_init_pos * (-rate)
	%bg_overlay1.position = ov1_pos
	%bg_overlay2.position = ov2_pos
