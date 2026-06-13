extends Node

const ROW_TEXT_COLOR := Color(0.18, 0.15, 0.12, 1)
const ROW_FONT_SIZE := 16
const EMPTY_HINT_COLOR := Color(0.45, 0.4, 0.35, 1)

var _list_container: VBoxContainer


func setup(list_container: VBoxContainer) -> void:
	_list_container = list_container


func clear() -> void:
	if _list_container == null:
		return
	for child in _list_container.get_children():
		child.queue_free()


func show_summaries(summaries: Array[Dictionary]) -> void:
	clear()
	if summaries.is_empty():
		_add_empty_hint()
		return

	for summary in summaries:
		_add_row(str(summary["display_ko"]), int(summary["count"]))


func _add_empty_hint() -> void:
	var label := Label.new()
	label.layout_mode = 2
	label.text = "—"
	label.add_theme_color_override("font_color", EMPTY_HINT_COLOR)
	label.add_theme_font_size_override("font_size", ROW_FONT_SIZE)
	_list_container.add_child(label)


func _add_row(display_ko: String, count: int) -> void:
	var label := Label.new()
	label.layout_mode = 2
	label.text = "%s : %d" % [display_ko, count]
	label.add_theme_color_override("font_color", ROW_TEXT_COLOR)
	label.add_theme_font_size_override("font_size", ROW_FONT_SIZE)
	_list_container.add_child(label)
