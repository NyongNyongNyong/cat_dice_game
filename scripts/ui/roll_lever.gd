class_name RollLever
extends Control

signal speed_changed(multiplier: float)

const NOTCHES: Array[Dictionary] = [
	{"label": "STOP", "speed": 0.0},
	{"label": "x1", "speed": 1.0},
	{"label": "x2", "speed": 2.0},
	{"label": "x3", "speed": 3.0},
]
const DEFAULT_SIZE := Vector2(260, 160)

# 레버는 전부 _draw()로 그리므로 Theme가 먹지 않는다. 대신 색·치수를 인스펙터에
# 노출해 에디터에서 조정할 수 있게 한다.
@export_group("Appearance")
@export var track_color := Color(0.2, 0.17, 0.14, 1.0)
@export var track_fill_color := Color(0.78, 0.62, 0.28, 1.0)
@export var knob_color := Color(0.93, 0.88, 0.76, 1.0)
@export var knob_border_color := Color(0.36, 0.28, 0.16, 1.0)
@export var label_color := Color(0.18, 0.15, 0.12, 1.0)
@export var label_font_size := 18
@export var disabled_alpha := 0.45

@export_group("Layout")
@export var track_width := 14.0
@export var track_left := 42.0
@export var track_top := 18.0
@export var knob_radius := 22.0
@export var label_offset_x := 20.0

var _notch_index := 0
var _dragging := false
var _disabled := false


func _ready() -> void:
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = DEFAULT_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(true)


func set_disabled(disabled: bool) -> void:
	_disabled = disabled
	modulate.a = disabled_alpha if _disabled else 1.0
	if _disabled:
		_set_notch(0)
	queue_redraw()


func get_speed_multiplier() -> float:
	return float(NOTCHES[_notch_index]["speed"])


func is_stopped() -> bool:
	return _notch_index == 0


func _gui_input(event: InputEvent) -> void:
	if _disabled:
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index != MOUSE_BUTTON_LEFT:
			return
		_dragging = mouse_event.pressed
		if _dragging:
			_set_notch(_notch_from_position(mouse_event.position))
		else:
			_set_notch(0)
	elif event is InputEventMouseMotion and _dragging:
		var motion_event := event as InputEventMouseMotion
		_set_notch(_notch_from_position(motion_event.position))


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT and _dragging and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_dragging = false
		_set_notch(0)


func _process(_delta: float) -> void:
	if _dragging and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_dragging = false
		_set_notch(0)


func _draw() -> void:
	var track_rect := _track_rect()
	var knob_center := _knob_center(_notch_index)
	var font := get_theme_default_font()

	draw_rect(track_rect, track_color, true)
	var fill_height := maxf(0.0, knob_center.y - track_rect.position.y)
	if fill_height > 0:
		draw_rect(Rect2(track_rect.position, Vector2(track_rect.size.x, fill_height)), track_fill_color, true)

	for i in NOTCHES.size():
		var center := _knob_center(i)
		draw_circle(Vector2(track_rect.get_center().x, center.y), 3.0, label_color)
		var label := str(NOTCHES[i]["label"])
		var text_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, label_font_size)
		draw_string(
			font,
			Vector2(track_rect.position.x + track_rect.size.x + label_offset_x, center.y + text_size.y * 0.35),
			label,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			label_font_size,
			label_color
		)

	draw_circle(knob_center, knob_radius, knob_color)
	draw_circle(knob_center, knob_radius, knob_border_color, false, 4.0)


func _set_notch(next_index: int) -> void:
	next_index = clampi(next_index, 0, NOTCHES.size() - 1)
	if _notch_index == next_index:
		return
	_notch_index = next_index
	speed_changed.emit(get_speed_multiplier())
	queue_redraw()


func _notch_from_position(position: Vector2) -> int:
	var track_rect := _track_rect()
	var ratio := inverse_lerp(track_rect.position.y, track_rect.position.y + track_rect.size.y, position.y)
	return int(round(clampf(ratio, 0.0, 1.0) * float(NOTCHES.size() - 1)))


func _knob_center(index: int) -> Vector2:
	var track_rect := _track_rect()
	var ratio := float(index) / float(maxi(NOTCHES.size() - 1, 1))
	return Vector2(track_rect.get_center().x, lerpf(track_rect.position.y, track_rect.position.y + track_rect.size.y, ratio))


func _track_rect() -> Rect2:
	return Rect2(
		Vector2(track_left, track_top),
		Vector2(track_width, maxf(size.y - track_top * 2.0, 1.0))
	)
