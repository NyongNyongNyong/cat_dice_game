extends Node

const DICE_SCENE := preload("res://scenes/dice/dice.tscn")
const TOOLTIP_CURSOR_GAP := Vector2(12.0, 10.0)
const MINI_DICE_SIZE := 32.0
const FACE_SEPARATION := 4
const CONTENT_SEPARATION := 6
const DESC_LINE_HEIGHT := 16.0
const DESC_FONT_SIZE := 12
const PANEL_PADDING := 4.0
const BORDER_WIDTH := 2.0
const EDGE_MARGIN := 4.0

var _popup_layer: Control
var _tooltip: PanelContainer
var _content: VBoxContainer
var _faces_row: HBoxContainer
var _desc_box: VBoxContainer
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
	_rebuild_descriptions(faces)
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

	_content = VBoxContainer.new()
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_theme_constant_override("separation", CONTENT_SEPARATION)
	_content.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_content.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	_faces_row = HBoxContainer.new()
	_faces_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_faces_row.add_theme_constant_override("separation", FACE_SEPARATION)
	_faces_row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_faces_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	_desc_box = VBoxContainer.new()
	_desc_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_desc_box.add_theme_constant_override("separation", 2)
	_desc_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_desc_box.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_desc_box.visible = false

	_content.add_child(_faces_row)
	_content.add_child(_desc_box)
	_tooltip.add_child(_content)
	_popup_layer.add_child(_tooltip)


func _rebuild_face_row(
	faces: Array[Resource],
	context_faces: Array[Resource],
	dice_index: int,
) -> void:
	# queue_free()만 하면 프레임 끝까지 자식이 트리에 남아, 같은 프레임에 도는
	# _fit_and_position_tooltip의 get_child_count()가 옛 자식까지 세어 툴팁이
	# 커진다. 트리에서 즉시 제거한다.
	for child in _faces_row.get_children():
		_faces_row.remove_child(child)
		child.queue_free()

	var board := context_faces.duplicate()
	for face in faces:
		if face == null:
			continue

		# 주사위 씬 루트는 custom_minimum_size=64가 박혀 있다. 인스턴스에서 32로
		# 덮어써야 툴팁이 콘텐츠 크기에 맞게 작게 잡힌다.
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


func _rebuild_descriptions(faces: Array[Resource]) -> void:
	for child in _desc_box.get_children():
		_desc_box.remove_child(child)
		child.queue_free()

	var seen: Dictionary = {}
	var lines: Array[String] = []
	for face in faces:
		if face == null or not face.has_method("is_number") or face.is_number():
			continue
		var properties: Array = face.properties if "properties" in face else []
		for property in properties:
			if property == null or not property.has_method("get_description"):
				continue
			var description := String(property.get_description())
			if description.is_empty():
				continue
			var glyph := ""
			if property.has_method("get_display_text"):
				glyph = String(property.get_display_text(face, {}, ""))
			var key := "%s|%s" % [glyph, description]
			if seen.has(key):
				continue
			seen[key] = true
			if glyph.is_empty():
				lines.append(description)
			else:
				lines.append("%s — %s" % [glyph, description])

	_desc_box.visible = not lines.is_empty()
	for line in lines:
		var label := Label.new()
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.text = line
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", DESC_FONT_SIZE)
		label.add_theme_color_override("font_color", Color(0.92, 0.88, 0.78, 1.0))
		label.custom_minimum_size = Vector2(0.0, DESC_LINE_HEIGHT)
		_desc_box.add_child(label)


func _fit_and_position_tooltip() -> void:
	if _pending_dice_view == null or not is_instance_valid(_pending_dice_view):
		return

	var count := _faces_row.get_child_count()
	if count <= 0:
		_tooltip.visible = false
		return

	# 각 미니 주사위를 32로 고정한다. 주사위 씬 루트의 64px 최소 크기·컨테이너
	# min-size 전파에 맡기면 첫 칸만 크기가 잡히고 나머지가 접히므로 직접 설정한다.
	var mini_size := Vector2(MINI_DICE_SIZE, MINI_DICE_SIZE)
	for child in _faces_row.get_children():
		if child is Control:
			var mini: Control = child as Control
			mini.custom_minimum_size = mini_size
			mini.size = mini_size

	# 콘텐츠 크기는 면 개수·설명 줄로 직접 계산한다.
	var faces_width := MINI_DICE_SIZE * count + FACE_SEPARATION * maxi(count - 1, 0)
	var desc_count := _desc_box.get_child_count() if _desc_box.visible else 0
	var desc_height := 0.0
	var desc_width := 0.0
	if desc_count > 0:
		desc_height = DESC_LINE_HEIGHT * desc_count + 2.0 * maxi(desc_count - 1, 0)
		# 설명 줄이 길 수 있어 면 행보다 넓게 잡는다.
		desc_width = maxf(faces_width, 220.0)
		_desc_box.custom_minimum_size = Vector2(desc_width, desc_height)
		_desc_box.size = Vector2(desc_width, desc_height)
	else:
		_desc_box.custom_minimum_size = Vector2.ZERO
		_desc_box.size = Vector2.ZERO

	var content_width := maxf(faces_width, desc_width)
	var content_height := MINI_DICE_SIZE
	if desc_count > 0:
		content_height += CONTENT_SEPARATION + desc_height

	_faces_row.custom_minimum_size = Vector2(faces_width, MINI_DICE_SIZE)
	_faces_row.size = Vector2(faces_width, MINI_DICE_SIZE)
	_content.custom_minimum_size = Vector2(content_width, content_height)
	_content.size = Vector2(content_width, content_height)

	var fitted := Vector2(content_width, content_height) + _panel_chrome_size()
	_tooltip.custom_minimum_size = fitted
	_tooltip.size = fitted
	_position_tooltip(_pending_dice_view)


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


func _position_tooltip(_dice_view: Control) -> void:
	# 전역 마우스 기준으로 붙인다. (중첩/축소된 popup layer local 좌표에 의존하지 않음)
	var mouse := _popup_layer.get_global_mouse_position()
	var size := _tooltip.size
	var global_pos := Vector2(
		mouse.x + TOOLTIP_CURSOR_GAP.x,
		mouse.y - TOOLTIP_CURSOR_GAP.y - size.y,
	)
	var viewport_rect := _popup_layer.get_viewport().get_visible_rect()
	if global_pos.y < viewport_rect.position.y + EDGE_MARGIN:
		global_pos.y = mouse.y + TOOLTIP_CURSOR_GAP.y
	_tooltip.global_position = _clamp_tooltip_to_viewport(global_pos, viewport_rect)


func _clamp_tooltip_to_viewport(global_pos: Vector2, viewport_rect: Rect2) -> Vector2:
	var max_x := maxf(
		viewport_rect.position.x + EDGE_MARGIN,
		viewport_rect.end.x - _tooltip.size.x - EDGE_MARGIN,
	)
	var max_y := maxf(
		viewport_rect.position.y + EDGE_MARGIN,
		viewport_rect.end.y - _tooltip.size.y - EDGE_MARGIN,
	)
	return Vector2(
		clampf(global_pos.x, viewport_rect.position.x + EDGE_MARGIN, max_x),
		clampf(global_pos.y, viewport_rect.position.y + EDGE_MARGIN, max_y),
	)
