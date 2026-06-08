extends Control

const FACE_COLOR := Color(0.95, 0.93, 0.88, 1.0)
const DIM_FACE_COLOR := Color(0.82, 0.8, 0.74, 1.0)
const HIGHLIGHT_FACE_COLOR := Color(1.0, 0.96, 0.78, 1.0)
const HIGHLIGHT_BORDER_COLOR := Color(0.85, 0.55, 0.12, 1.0)
const SELECTED_BORDER_COLOR := Color(0.22, 0.48, 0.86, 1.0)
const PIP_COLOR := Color(0.18, 0.15, 0.12, 1.0)
const DIM_PIP_COLOR := Color(0.18, 0.15, 0.12, 0.45)
const PIP_RADIUS_RATIO := 0.07
const FACE_TEXT_COLOR := Color(0.18, 0.15, 0.12, 1.0)
const DIM_FACE_TEXT_COLOR := Color(0.18, 0.15, 0.12, 0.45)
const FACE_TEXT_SIZE := 34

const PIP_LAYOUTS: Dictionary = {
	1: [Vector2(0.5, 0.5)],
	2: [Vector2(0.3, 0.3), Vector2(0.7, 0.7)],
	3: [Vector2(0.3, 0.3), Vector2(0.5, 0.5), Vector2(0.7, 0.7)],
	4: [Vector2(0.3, 0.3), Vector2(0.7, 0.3), Vector2(0.3, 0.7), Vector2(0.7, 0.7)],
	5: [
		Vector2(0.3, 0.3),
		Vector2(0.7, 0.3),
		Vector2(0.5, 0.5),
		Vector2(0.3, 0.7),
		Vector2(0.7, 0.7),
	],
	6: [
		Vector2(0.3, 0.25),
		Vector2(0.3, 0.5),
		Vector2(0.3, 0.75),
		Vector2(0.7, 0.25),
		Vector2(0.7, 0.5),
		Vector2(0.7, 0.75),
	],
}

var _face_value: int = 0
var _face: Resource
var _face_display_text: String = ""
var _show_placeholder: bool = true
var _highlighted: bool = false
var _dimmed: bool = false
var _selected: bool = false


func set_face(face: Resource, resolved_value: int) -> void:
	_face = face
	_face_display_text = ""
	_face_value = 0
	if _uses_pip_layout(face):
		_face_value = face.get_base_number_value()
	elif face != null and face.has_method("get_display_text"):
		_face_display_text = face.get_display_text({"resolved_value": resolved_value})
	_show_placeholder = false
	_highlighted = false
	_dimmed = false
	queue_redraw()


func show_placeholder() -> void:
	_show_placeholder = true
	_highlighted = false
	_dimmed = false
	_selected = false
	queue_redraw()


func set_selected(on: bool) -> void:
	_selected = on
	queue_redraw()


func clear_selection() -> void:
	_selected = false
	queue_redraw()


func set_highlighted(on: bool) -> void:
	_highlighted = on
	queue_redraw()


func set_dimmed(on: bool) -> void:
	_dimmed = on
	queue_redraw()


func _draw() -> void:
	var face_rect := Rect2(Vector2.ZERO, size)
	var face_color := FACE_COLOR
	if _highlighted:
		face_color = HIGHLIGHT_FACE_COLOR
	elif _dimmed:
		face_color = DIM_FACE_COLOR

	draw_rect(face_rect, face_color)

	if _highlighted:
		draw_rect(face_rect, HIGHLIGHT_BORDER_COLOR, false, 4.0)
	elif _selected:
		draw_rect(face_rect, SELECTED_BORDER_COLOR, false, 4.0)

	if _show_placeholder:
		return

	if _uses_pip_layout(_face):
		_draw_pips()
	elif not _face_display_text.is_empty():
		_draw_face_text(_face_display_text)


func _uses_pip_layout(face: Resource) -> bool:
	return face != null and face.has_method("is_number") and face.is_number()


func _draw_pips() -> void:
	var pip_color := DIM_PIP_COLOR if _dimmed else PIP_COLOR
	var pip_radius := minf(size.x, size.y) * PIP_RADIUS_RATIO
	for pos: Vector2 in PIP_LAYOUTS.get(_face_value, []):
		var center := Vector2(pos.x * size.x, pos.y * size.y)
		draw_circle(center, pip_radius, pip_color)


func _draw_face_text(text: String) -> void:
	var font := get_theme_default_font()
	var font_size := FACE_TEXT_SIZE
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var position := Vector2(
		(size.x - text_size.x) * 0.5,
		(size.y + text_size.y * 0.35) * 0.5
	)
	var color := DIM_FACE_TEXT_COLOR if _dimmed else FACE_TEXT_COLOR
	draw_string(font, position, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
