class_name RollLever
extends Control

signal speed_changed(multiplier: float)

const NOTCHES: Array[Dictionary] = [
	{"label": "STOP", "speed": 0.0},
	{"label": "x1", "speed": 1.0},
	{"label": "x2", "speed": 2.0},
	{"label": "x3", "speed": 3.0},
]
const TRACK_COLOR := Color(0.2, 0.17, 0.14, 1.0)
const TRACK_FILL_COLOR := Color(0.78, 0.62, 0.28, 1.0)
const KNOB_COLOR := Color(0.93, 0.88, 0.76, 1.0)
const KNOB_BORDER_COLOR := Color(0.36, 0.28, 0.16, 1.0)
const LABEL_COLOR := Color(0.18, 0.15, 0.12, 1.0)
const DISABLED_ALPHA := 0.45
const TRACK_WIDTH := 14.0
const KNOB_RADIUS := 22.0
const TRACK_LEFT := 42.0
const TRACK_TOP := 18.0

var _notch_index := 0
var _dragging := false
var _disabled := false


func _ready() -> void:
	custom_minimum_size = Vector2(260, 160)
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(true)


func set_disabled(disabled: bool) -> void:
	_disabled = disabled
	modulate.a = DISABLED_ALPHA if _disabled else 1.0
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
	var font_size := 18

	draw_rect(track_rect, TRACK_COLOR, true)
	var fill_height := maxf(0.0, knob_center.y - track_rect.position.y)
	if fill_height > 0:
		draw_rect(Rect2(track_rect.position, Vector2(track_rect.size.x, fill_height)), TRACK_FILL_COLOR, true)

	for i in NOTCHES.size():
		var center := _knob_center(i)
		draw_circle(Vector2(track_rect.get_center().x, center.y), 3.0, LABEL_COLOR)
		var label := str(NOTCHES[i]["label"])
		var text_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		draw_string(
			font,
			Vector2(track_rect.position.x + track_rect.size.x + 20.0, center.y + text_size.y * 0.35),
			label,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			font_size,
			LABEL_COLOR
		)

	draw_circle(knob_center, KNOB_RADIUS, KNOB_COLOR)
	draw_circle(knob_center, KNOB_RADIUS, KNOB_BORDER_COLOR, false, 4.0)


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
		Vector2(TRACK_LEFT, TRACK_TOP),
		Vector2(TRACK_WIDTH, maxf(size.y - TRACK_TOP * 2.0, 1.0))
	)
