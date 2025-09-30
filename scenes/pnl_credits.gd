@tool
extends PanelContainer


@warning_ignore("unused_private_class_variable")
@export_tool_button("Print credits") var _btn: Callable = print_out
@export var in_main_menu: bool = false

signal pnl_closed


func _ready() -> void:
	%btn_quit.visible = not in_main_menu


func print_out() -> void:
	var f_content: String = FileAccess.get_file_as_string("res://credits.md")
	var parsed: String = MarkdownUtl.convert_to_bbcode(f_content)
	print(parsed)


func _on_btn_close_pressed() -> void:
	hide()
	pnl_closed.emit()
func _on_btn_quit_pressed() -> void:
	Mng.quit()


func _on_lb_credits_meta_clicked(meta: Variant) -> void:
	OS.shell_open(meta)
