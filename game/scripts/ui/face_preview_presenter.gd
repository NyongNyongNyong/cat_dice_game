extends Node

const DICE_SCENE := preload("res://scenes/dice/dice.tscn")
const TOOLTIP_OFFSET := Vector2(0.0, -8.0)
const MINI_DICE_SIZE := 32.0
const FACE_SEPARATION := 4
const PANEL_PADDING := 4.0
const BORDER_WIDTH := 2.0

var _popup_layer: Control
var _tooltip: PanelContainer
var _faces_row: HBoxContainer
var _active := false
var _pending_dice_view: Control


func setup(popup_layer: Control) -> void:
	_popup_layer = popup_layer
	_build_tooltip()


func set_active(active: bool) -> void:
	_active = active
	if not active:
		hide_preview()


func show_die_faces(
	dice_view: Control,
	faces: Array[Resource],
	context_faces: Array[Resource],
	dice_index: int,
) -> void:
	if not _active or faces.is_empty():
		return

	_rebuild_face_row(faces, context_faces, dice_index)
	_pending_dice_view = dice_view
	_tooltip.visible = true
	_fit_and_position_tooltip.call_deferred()


func hide_preview() -> void:
	_pending_dice_view = null
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
	style.set_border_width_all(int(BORDER_WIDTH))
	style.set_corner_radius_all(4)
	style.content_margin_left = PANEL_PADDING
	style.content_margin_top = PANEL_PADDING
	style.content_margin_right = PANEL_PADDING
	style.content_margin_bottom = PANEL_PADDING
	_tooltip.add_theme_stylebox_override("panel", style)

	_faces_row = HBoxContainer.new()
	_faces_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_faces_row.add_theme_constant_override("separation", FACE_SEPARATION)
	_faces_row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_faces_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_tooltip.add_child(_faces_row)
	_popup_layer.add_child(_tooltip)


func _rebuild_face_row(
	faces: Array[Resource],
	context_faces: Array[Resource],
	dice_index: int,
) -> void:
	for child in _faces_row.get_children():
		child.queue_free()

	var board := context_faces.duplicate()
	for face in faces:
		if face == null:
			continue

		var mini: Control = DICE_SCENE.instantiate()
		mini.layout_mode = 2
		mini.custom_minimum_size = Vector2(MINI_DICE_SIZE, MINI_DICE_SIZE)
		mini.size = Vector2(MINI_DICE_SIZE, MINI_DICE_SIZE)
		mini.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		mini.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		mini.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var trial_board := board.duplicate()
		if dice_index >= 0 and dice_index < trial_board.size():
			trial_board[dice_index] = face
		elif dice_index >= trial_board.size():
			trial_board.append(face)
		var resolved := _resolve_face_value(face, trial_board)
		mini.set_face(face, resolved)
		_faces_row.add_child(mini)


func _fit_and_position_tooltip() -> void:
	if _pending_dice_view == null or not is_instance_valid(_pending_dice_view):
		return

	_tooltip.custom_minimum_size = Vector2.ZERO
	_faces_row.custom_minimum_size = Vector2.ZERO
	_tooltip.reset_size()
	_faces_row.reset_size()

	for child in _faces_row.get_children():
		if child is Control:
			var dice: Control = child as Control
			dice.reset_size()
			var dice_size := dice.get_combined_minimum_size()
			if dice_size == Vector2.ZERO:
				dice_size = Vector2(MINI_DICE_SIZE, MINI_DICE_SIZE)
			dice.custom_minimum_size = dice_size
			dice.size = dice_size

	var content_size := _faces_row.get_combined_minimum_size()
	if content_size == Vector2.ZERO:
		content_size = _measure_faces_row()

	_faces_row.custom_minimum_size = content_size
	_faces_row.size = content_size

	_tooltip.reset_size()
	var fitted := _tooltip.get_minimum_size()
	if fitted == Vector2.ZERO:
		fitted = content_size + _panel_chrome_size()
	_tooltip.custom_minimum_size = fitted
	_tooltip.size = fitted
	_position_tooltip(_pending_dice_view)


func _measure_faces_row() -> Vector2:
	var width := 0.0
	var height := 0.0
	var count := _faces_row.get_child_count()
	for i in count:
		var child := _faces_row.get_child(i) as Control
		if child == null:
			continue
		width += child.size.x
		height = maxf(height, child.size.y)
	if count > 1:
		width += FACE_SEPARATION * (count - 1)
	return Vector2(width, height)


func _panel_chrome_size() -> Vector2:
	var style := _tooltip.get_theme_stylebox("panel") as StyleBoxFlat
	if style == null:
		return Vector2((PANEL_PADDING + BORDER_WIDTH) * 2.0, (PANEL_PADDING + BORDER_WIDTH) * 2.0)
	return Vector2(
		style.content_margin_left + style.content_margin_right
			+ style.border_width_left + style.border_width_right,
		style.content_margin_top + style.content_margin_bottom
			+ style.border_width_top + style.border_width_bottom,
	)


func _resolve_face_value(face: Resource, context_faces: Array[Resource]) -> int:
	if face.has_method("resolve_number_value"):
		return face.resolve_number_value({"faces": context_faces})
	return 1


func _position_tooltip(dice_view: Control) -> void:
	var dice_rect := dice_view.get_global_rect()
	var layer_transform := _popup_layer.get_global_transform().affine_inverse()
	var anchor := layer_transform * dice_rect.get_center()
	_tooltip.position = anchor + TOOLTIP_OFFSET - Vector2(_tooltip.size.x * 0.5, _tooltip.size.y)
