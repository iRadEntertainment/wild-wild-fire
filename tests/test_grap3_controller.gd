extends MeshInstance3D


@onready var cam: Camera3D = $cam

var dir2d: Vector2
var elevation_dir: float
var forward_velocity: float
var MIN_FORW_VELOCITY: float = 2.0 #m/s
var elevation_velocity: float
var speed: float = 3.0 #m/s
var rot_speed: float = 3.0 #m/s
var rotation_angle: float

const CAM_OFFSET := Vector3(0.0, 2.8, 4.2)
var cam_angle: float = 0.0


func _enter_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _physics_process(d: float) -> void:
	speed = 0.25
	rot_speed = 0.05
	
	dir2d = Input.get_vector(&"steer_left", &"steer_right", &"throttle_down", &"throttle_up")
	elevation_dir = Input.get_axis(&"pitch_down", &"pitch_up")
	
	var rot_target: float = lerp_angle(0.0, PI/16.0, -dir2d.x)
	rotation_angle = move_toward(rotation_angle, rot_target * rot_speed, d)
	forward_velocity = move_toward(forward_velocity, max(dir2d.y * speed, MIN_FORW_VELOCITY * d), d)
	elevation_velocity = move_toward(elevation_velocity, elevation_dir * speed, d)
	
	var translate_vec: Vector3 = Vector3(0.0, elevation_velocity, -forward_velocity)
	rotate_y(rotation_angle)
	rotation.x = lerp_angle(0.0, PI/8.0, elevation_velocity/speed)
	translate_object_local(translate_vec)
	
	cam.global_position = global_position + CAM_OFFSET.rotated(Vector3.UP, global_rotation.y + cam_angle)
	cam.look_at(global_position)


func _input(event: InputEvent) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED: return
	if event is InputEventMouseMotion:
		var angle_delta: float = lerp(0.0, PI, -event.relative.x / get_window().size.x)
		cam_angle = wrapf(cam_angle + angle_delta, 0, TAU)
