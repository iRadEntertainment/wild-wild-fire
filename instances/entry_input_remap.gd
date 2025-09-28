extends HBoxContainer
class_name EntryInputRemap


@onready var lb_input: Label = %lb_input
@onready var btn_input: Button = %btn_input

@export var action_name: StringName:
	set(value):
		action_name = value
		_update_ui()

signal rebind_requested(action_name: StringName, entry: EntryInputRemap)


func _ready() -> void:
	_update_ui()
	btn_input.pressed.connect(_on_btn_input_pressed)


func _on_btn_input_pressed() -> void:
	emit_signal("rebind_requested", action_name, self)


func update_input_text() -> void:
	btn_input.text = _events_to_string(action_name)


func _update_ui() -> void:
	if not is_node_ready():
		return
	lb_input.text = str(action_name).capitalize()
	btn_input.text = _events_to_string(action_name)


func _events_to_string(action: StringName) -> String:
	var events := InputMap.action_get_events(action)
	if events.is_empty():
		return ""
	var parts: Array[String] = []
	for e: InputEvent in events:
		parts.append(e.as_text())
	return " / ".join(parts)
