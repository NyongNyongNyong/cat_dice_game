extends Control

const FACE_COLOR := Color(0.95, 0.93, 0.88, 1.0)
const DIM_FACE_COLOR := Color(0.82, 0.8, 0.74, 1.0)
const HIGHLIGHT_FACE_COLOR := Color(1.0, 0.96, 0.78, 1.0)
const HIGHLIGHT_BORDER_COLOR := Color(0.85, 0.55, 0.12, 1.0)
const PIP_COLOR := Color(0.18, 0.15, 0.12, 1.0)
const DIM_PIP_COLOR := Color(0.18, 0.15, 0.12, 0.45)
const PIP_RADIUS_RATIO := 0.07

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
var _show_placeholder: bool = true
var _highlighted: bool = false
var _dimmed: bool = false


func set_value(face_value: int) -> void:
	_face_value = face_value
	_show_placeholder = false
	_highlighted = false
	_dimmed = false
	queue_redraw()


func show_placeholder() -> void:
	_show_placeholder = true
	_highlighted = false
	_dimmed = false
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

	if _show_placeholder:
		return

	var pip_color := DIM_PIP_COLOR if _dimmed else PIP_COLOR
	var pip_radius := minf(size.x, size.y) * PIP_RADIUS_RATIO
	for pos: Vector2 in PIP_LAYOUTS.get(_face_value, []):
		var center := Vector2(pos.x * size.x, pos.y * size.y)
		draw_circle(center, pip_radius, pip_color)
