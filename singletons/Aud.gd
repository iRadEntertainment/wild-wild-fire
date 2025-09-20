# Singleton Aud AUDIO MANAGER and PLAYER
extends Node


#region Music
var _tw_music: Tween

func play_music_main_menu() -> void:
	if $music.playing: return
	$music.volume_linear = 0.0
	if _tw_music: _tw_music.kill()
	_tw_music = create_tween()
	_tw_music.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	_tw_music.tween_property($music, "volume_linear", 0.8, 2.0)
	$music.play()


func stop_music() -> void:
	if not $music.playing: return
	if _tw_music: _tw_music.kill()
	_tw_music = create_tween()
	_tw_music.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	_tw_music.tween_property($music, "volume_linear", 0.0, 4.0)
	_tw_music.tween_callback($music.stop)
#endregion


#region UI
func play_btn_hover() -> void: $ui_hover.play()
func play_btn_press() -> void: $ui_press.play()


func connect_all_buttons_sounds(from_node: Control) -> void:
	for btn: Button in from_node.find_children("*", "Button", true, false):
		if not btn.mouse_entered.is_connected(play_btn_hover):
			btn.mouse_entered.connect(play_btn_hover)
		if not btn.pressed.is_connected(play_btn_hover):
			btn.pressed.connect(play_btn_hover)
#endregion
