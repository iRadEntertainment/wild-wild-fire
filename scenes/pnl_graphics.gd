extends PanelContainer


const MODE_ITEMS := [
	{ "label": "Windowed", "value": DisplayServer.WINDOW_MODE_WINDOWED },
	{ "label": "Borderless Fullscreen", "value": DisplayServer.WINDOW_MODE_FULLSCREEN },
	{ "label": "Exclusive Fullscreen", "value": DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN }
]

const VSYNC_ITEMS := [
	{ "label": "Off", "value": DisplayServer.VSYNC_DISABLED },
	{ "label": "On", "value": DisplayServer.VSYNC_ENABLED },
	{ "label": "Adaptive", "value": DisplayServer.VSYNC_ADAPTIVE },
	{ "label": "Mailbox", "value": DisplayServer.VSYNC_MAILBOX }
]

const BASE_RESOLUTIONS := [
	Vector2i(1280, 720), Vector2i(1366, 768), Vector2i(1600, 900), Vector2i(1920, 1080),
	Vector2i(2560, 1440), Vector2i(3840, 2160),
	Vector2i(1280, 800), Vector2i(1440, 900), Vector2i(1680, 1050), Vector2i(1920, 1200),
	Vector2i(2560, 1600), Vector2i(3440, 1440)
]


var game_env: Environment = preload("res://assets/materials/game_env.tres")



func _ready() -> void:
	_populate_mode()
	_populate_vsync()
	_populate_resolutions()
	_select_current_values()
	_connect_signals()


func _process(delta: float) -> void:
	%Airplane.rotate_y(PI/4.0 * delta)
	%lb_fps.text = "FPS %.1f" % Performance.get_monitor(Performance.TIME_FPS)


func _populate_mode() -> void:
	%opt_window_mode.clear()
	for i: int in MODE_ITEMS.size():
		var item: Dictionary = MODE_ITEMS[i]
		%opt_window_mode.add_item(item.label)
		%opt_window_mode.set_item_metadata(i, item.value)


func _populate_vsync() -> void:
	%opt_vsync.clear()
	for i: int in VSYNC_ITEMS.size():
		var item: Dictionary = VSYNC_ITEMS[i]
		%opt_vsync.add_item(item.label)
		%opt_vsync.set_item_metadata(i, item.value)


func _populate_resolutions() -> void:
	%opt_res.clear()
	for i: int in BASE_RESOLUTIONS.size():
		var r: Vector2i = BASE_RESOLUTIONS[i]
		var label := "%d×%d" % [r.x, r.y]
		%opt_res.add_item(label)
		%opt_res.set_item_metadata(i, r)


func _select_current_values() -> void:
	var cur_mode := DisplayServer.window_get_mode()
	for i in %opt_window_mode.item_count:
		if int(%opt_window_mode.get_item_metadata(i)) == cur_mode:
			%opt_window_mode.select(i)
			break
	
	var cur_vsync := DisplayServer.window_get_vsync_mode()
	for i in %opt_vsync.item_count:
		if int(%opt_vsync.get_item_metadata(i)) == cur_vsync:
			%opt_vsync.select(i)
			break
	
	var cur_size: Vector2i = get_window().size
	var best_idx := -1
	var best_diff := INF
	for i in %opt_res.item_count:
		var r: Vector2i = %opt_res.get_item_metadata(i)
		var diff: int = abs(r.x - cur_size.x) + abs(r.y - cur_size.y)
		if diff < best_diff:
			best_diff = diff
			best_idx = i
	if best_idx >= 0:
		%opt_res.select(best_idx)
	
	%sl_max_fps.value = Engine.max_fps
	%lb_max_fps.text = str(Engine.max_fps)
	%ck_glow.button_pressed = game_env.glow_enabled


func _connect_signals() -> void:
	if not %opt_window_mode.is_connected("item_selected", Callable(self, "_on_mode_selected")):
		%opt_window_mode.item_selected.connect(_on_mode_selected)
	if not %opt_vsync.is_connected("item_selected", Callable(self, "_on_vsync_selected")):
		%opt_vsync.item_selected.connect(_on_vsync_selected)
	if not %opt_res.is_connected("item_selected", Callable(self, "_on_resolution_selected")):
		%opt_res.item_selected.connect(_on_resolution_selected)


func _on_mode_selected(index: int) -> void:
	var mode := int(%opt_window_mode.get_item_metadata(index))
	DisplayServer.window_set_mode(mode)
	if mode == DisplayServer.WINDOW_MODE_WINDOWED:
		var sel_size := _get_selected_resolution_or_current()
		DisplayServer.window_set_size(sel_size)


func _on_vsync_selected(index: int) -> void:
	var vsync := int(%opt_vsync.get_item_metadata(index))
	DisplayServer.window_set_vsync_mode(vsync)


func _on_resolution_selected(index: int) -> void:
	var res_size: Vector2i = %opt_res.get_item_metadata(index)
	DisplayServer.window_set_size(res_size)


func _get_selected_resolution_or_current() -> Vector2i:
	if %opt_res.selected >= 0:
		return %opt_res.get_item_metadata(%opt_res.selected)
	return get_window().size


func _on_sl_max_fps_value_changed(value: float) -> void:
	Engine.max_fps = int(value)
	%lb_max_fps.text = str(value)
	if value == 29:
		%lb_max_fps.text = "Uncapped"
		Engine.max_fps = 0


func _on_ck_glow_toggled(toggled_on: bool) -> void: game_env.glow_enabled = toggled_on


func _on_sl_glow_strength_value_changed(value: float) -> void:
	%lb_glow_strength.text = ".02f" % value
	game_env.glow_strength = value
