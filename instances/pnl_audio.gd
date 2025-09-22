extends PanelContainer


func _ready() -> void:
	%btn_master_mute.button_pressed = AudioServer.is_bus_mute(0)
	%sl_master.value = AudioServer.get_bus_volume_linear(0)
	%lb_master.text = "%.02f" % AudioServer.get_bus_volume_linear(0)
	%btn_sfx_mute.button_pressed = AudioServer.is_bus_mute(1)
	%sl_sfx.value = AudioServer.get_bus_volume_linear(1)
	%lb_sfx.text = "%.02f" % AudioServer.get_bus_volume_linear(1)
	%btn_music_mute.button_pressed = AudioServer.is_bus_mute(2)
	%sl_music.value = AudioServer.get_bus_volume_linear(2)
	%lb_music.text = "%.02f" % AudioServer.get_bus_volume_linear(2)
	%btn_ui_mute.button_pressed = AudioServer.is_bus_mute(3)
	%sl_ui.value = AudioServer.get_bus_volume_linear(3)
	%lb_ui.text = "%.02f" % AudioServer.get_bus_volume_linear(3)


func _on_btn_master_mute_toggled(toggled_on: bool) -> void: AudioServer.set_bus_mute(0, toggled_on)
func _on_btn_sfx_mute_toggled(toggled_on: bool) -> void: AudioServer.set_bus_mute(1, toggled_on)
func _on_btn_music_mute_toggled(toggled_on: bool) -> void: AudioServer.set_bus_mute(2, toggled_on)
func _on_btn_ui_mute_toggled(toggled_on: bool) -> void: AudioServer.set_bus_mute(3, toggled_on)


func _on_sl_master_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(0, value)
	%lb_master.text = "%.02f" % AudioServer.get_bus_volume_linear(0)
func _on_sl_sfx_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(1, value)
	if not %sfx_test.playing: %sfx_test.play() # TODO: replace sound
	%lb_sfx.text = "%.02f" % AudioServer.get_bus_volume_linear(1)
func _on_sl_music_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(2, value)
	%lb_music.text = "%.02f" % AudioServer.get_bus_volume_linear(2)
func _on_sl_ui_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(3, value)
	%ui_test.play()
	%lb_ui.text = "%.02f" % AudioServer.get_bus_volume_linear(3)
