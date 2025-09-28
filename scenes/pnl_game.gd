extends PanelContainer


var _listening_action: StringName = &""
var _listening_entry: EntryInputRemap
var _capture_mouse: bool = true
var _capture_pad: bool = true


func _ready() -> void:
	%ck_scawy.button_pressed = Mng.is_scawy
	_populate()


func _process(delta: float) -> void:
	%Airport.rotate_y(PI/4.0 * delta)


func _populate() -> void:
	for child in %vb_inputs.get_children():
		child.queue_free()
	
	for action: StringName in InputMap.get_actions():
		if str(action).begins_with("ui_") or str(action).begins_with("editor_"):
			continue
		
		var entry: EntryInputRemap = preload("res://instances/entry_input_remap.tscn").instantiate()
		entry.action_name = action
		entry.rebind_requested.connect(_on_rebind_requested)
		%vb_inputs.add_child(entry)


#region Event listener
func _unhandled_input(event: InputEvent) -> void:
	if _listening_action == &"":
		return
	
	# Allow cancelling with Esc
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_cancel_listen()
		get_viewport().set_input_as_handled()
		return

	var chosen_event := _pick_event_from(event)
	if chosen_event == null:
		return
	
	_remove_event_from_all_actions(chosen_event)
	
	InputMap.action_erase_events(_listening_action)
	InputMap.action_add_event(_listening_action, chosen_event)
	
	if is_instance_valid(_listening_entry):
		_listening_entry.update_input_text()
	_listening_action = &""
	_listening_entry = null
	
	_save_custom_mapping()
	get_viewport().set_input_as_handled()


func _pick_event_from(event: InputEvent) -> InputEvent:
	# Keyboard
	if event is InputEventKey and event.pressed and not event.echo:
		return event
	# Mouse button
	if _capture_mouse and event is InputEventMouseButton and event.pressed:
		return event
	# Gamepad button
	if _capture_pad and event is InputEventJoypadButton and event.pressed:
		return event
	# Gamepad axis to virtual button (optional): pick only strong deflections
	if _capture_pad and event is InputEventJoypadMotion and abs(event.axis_value) >= 0.5:
		return event
	return null

func _remove_event_from_all_actions(ev: InputEvent) -> void:
	for action: StringName in InputMap.get_actions():
		for existing: InputEvent in InputMap.action_get_events(action):
			if ev.is_match(existing, true):
				InputMap.action_erase_event(action, existing)
				break

func _cancel_listen() -> void:
	if is_instance_valid(_listening_entry):
		_listening_entry.update_input_text()
	_listening_action = &""
	_listening_entry = null
#endregion


#region Save/Load mapping
const SAVE_PATH := "user://controls_remap.json"

func _save_custom_mapping() -> void:
	var controls: Dictionary = {}
	for action: StringName in InputMap.get_actions():
		if str(action).begins_with("ui_") or str(action).begins_with("editor_"):
			continue
		controls[action] = InputMap.action_get_events(action)
	
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	f.store_string( JSON.stringify(controls, "\t") )
	f.close()


func apply_saved_mapping_if_any() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var controls: Dictionary = JSON.parse_string(f.get_as_text())
	f.close()
	
	if controls.is_empty():
		return
	for action: StringName in controls.keys():
		InputMap.action_erase_events(action)
		for ev: InputEvent in controls[action]:
			InputMap.action_add_event(action, ev)
#endregion


func _on_rebind_requested(action_name: StringName, entry: EntryInputRemap) -> void:
	_listening_action = action_name
	_listening_entry = entry
	_listening_entry.btn_input.text = "Press any key/button… (Esc to cancel)"


func _on_ck_scawy_toggled(toggled_on: bool) -> void:
	Mng.is_scawy = toggled_on
