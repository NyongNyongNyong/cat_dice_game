extends Node

const PreviewCalculator := preload("res://scripts/core/reroll_preview_calculator.gd")
const TOOLTIP_OFFSET := Vector2(0.0, -12.0)

var _popup_layer: Control
var _tooltip: PanelContainer
var _label: Label
var _active := false
var _cache: Dictionary = {}
var _cache_board_key: String = ""


func setup(popup_layer: Control) -> void:
	_popup_layer = popup_layer
	_build_tooltip()


func set_active(active: bool) -> void:
	_active = active
	if not active:
		hide_preview()
		_clear_cache()


func invalidate_cache() -> void:
	_clear_cache()


func show_preview(
	dice_view: Control,
	dice_index: int,
	dice_values: Array[int],
	face_values: Array[int] = [],
) -> void:
	if not _active or dice_values.is_empty():
		return

	var board_key := _board_cache_key(dice_values)
	if board_key != _cache_board_key:
		_clear_cache()
		_cache_board_key = board_key

	var cache_key := "%d:%s" % [dice_index, _face_values_cache_key(face_values)]
	var preview
	if _cache.has(cache_key):
		preview = _cache[cache_key]
	else:
		preview = PreviewCalculator.compute(dice_values, dice_index, face_values)
		_cache[cache_key] = preview

	_label.text = _format_preview(preview)
	_tooltip.reset_size()
	_position_tooltip(dice_view)
	_tooltip.visible = true


func show_preview_result(dice_view: Control, preview) -> void:
	if not _active:
		return

	_label.text = _format_preview(preview)
	_tooltip.reset_size()
	_position_tooltip(dice_view)
	_tooltip.visible = true


func hide_preview() -> void:
	if _tooltip:
		_tooltip.visible = false


func _build_tooltip() -> void:
	_tooltip = PanelContainer.new()
	_tooltip.visible = false
	_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip.z_index = 12

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.11, 0.1, 0.92)
	style.border_color = Color(0.75, 0.68, 0.5, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 10.0
	style.content_margin_top = 6.0
	style.content_margin_right = 10.0
	style.content_margin_bottom = 6.0
	_tooltip.add_theme_stylebox_override("panel", style)

	_label = Label.new()
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_size_override("font_size", 16)
	_label.add_theme_color_override("font_color", Color(0.98, 0.96, 0.9, 1.0))
	_tooltip.add_child(_label)
	_popup_layer.add_child(_tooltip)


func _format_preview(preview) -> String:
	return "▲ %s  ▼ %s" % [_format_delta(preview.delta_up), _format_delta(preview.delta_down)]


func _format_delta(delta: int) -> String:
	if delta >= 0:
		return "+%d" % delta
	return "%d" % delta


func _position_tooltip(dice_view: Control) -> void:
	var dice_rect := dice_view.get_global_rect()
	var layer_transform := _popup_layer.get_global_transform().affine_inverse()
	var anchor := layer_transform * dice_rect.get_center()
	var tooltip_size := _tooltip.get_minimum_size()
	_tooltip.position = anchor + TOOLTIP_OFFSET - Vector2(tooltip_size.x * 0.5, tooltip_size.y)


func _board_cache_key(dice_values: Array[int]) -> String:
	var parts: PackedStringArray = []
	for value in dice_values:
		parts.append(str(value))
	return ",".join(parts)


func _face_values_cache_key(face_values: Array[int]) -> String:
	var parts: PackedStringArray = []
	for value in face_values:
		parts.append(str(value))
	return ",".join(parts)


func _clear_cache() -> void:
	_cache.clear()
	_cache_board_key = ""
