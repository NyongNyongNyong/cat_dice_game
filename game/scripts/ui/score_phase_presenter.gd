class_name ScorePhasePresenter
extends Node

const STEP_DELAY := 0.4
const NUMBER_STEP_DELAY := 0.12
const POPUP_RISE := 32.0

signal presentation_finished()

var _dice_row: Control
var _popup_layer: Control
var _dice_views: Array[Control] = []
var _left_value: Label
var _right_value: Label
var _status_label: Label


func setup(
	dice_row: Control,
	popup_layer: Control,
	left_value: Label,
	right_value: Label,
	status_label: Label,
) -> void:
	_dice_row = dice_row
	_popup_layer = popup_layer
	_left_value = left_value
	_right_value = right_value
	_status_label = status_label


func set_dice_views(dice_views: Array[Control]) -> void:
	_dice_views = dice_views


func play(evaluation: HandEvaluation) -> void:
	_dice_row.visible = true
	_clear_popups()
	_reset_score_board()

	for dice in _dice_views:
		dice.show_placeholder()

	for i in evaluation.dice_values.size():
		_dice_views[i].set_value(evaluation.dice_values[i])
		_dice_views[i].set_dimmed(true)

	await _play_number_sum(evaluation.dice_values)
	await _play_hand_steps(evaluation.steps)
	_clear_highlights()
	_clear_popups()
	presentation_finished.emit()


func _play_number_sum(values: Array[int]) -> void:
	var running := 0
	_left_value.text = "0"

	for i in values.size():
		_clear_highlights()
		_dice_views[i].set_dimmed(false)
		_dice_views[i].set_highlighted(true)
		running += values[i]
		_left_value.text = str(running)
		await _show_points_popup("+%d" % values[i], [i])
		await get_tree().create_timer(NUMBER_STEP_DELAY).timeout

	_clear_highlights()
	for dice in _dice_views:
		dice.set_dimmed(true)


func _play_hand_steps(steps: Array[HandStep]) -> void:
	var hand_running := 0
	_right_value.text = "0"

	for step in steps:
		if step.clear_before:
			_clear_highlights()

		_apply_highlights(step.highlight_indices)
		hand_running += step.points_added
		_right_value.text = str(hand_running)
		_status_label.text = "%s (+ %d)" % [step.display_ko, step.points_added]
		await _show_points_popup("+%d" % step.points_added, step.highlight_indices)
		await get_tree().create_timer(STEP_DELAY).timeout


func _apply_highlights(indices: Array[int]) -> void:
	var index_set: Dictionary = {}
	for idx in indices:
		index_set[idx] = true

	for i in _dice_views.size():
		var dice: Control = _dice_views[i]
		dice.set_dimmed(not index_set.has(i))
		dice.set_highlighted(index_set.has(i))


func _clear_highlights() -> void:
	for dice in _dice_views:
		dice.set_highlighted(false)
		dice.set_dimmed(true)


func _show_points_popup(text: String, highlight_indices: Array[int]) -> void:
	var popup := Label.new()
	popup.text = text
	popup.add_theme_font_size_override("font_size", 26)
	popup.add_theme_color_override("font_color", Color(0.72, 0.42, 0.08, 1.0))
	popup.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.9))
	popup.add_theme_constant_override("outline_size", 4)
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup.z_index = 10

	_popup_layer.add_child(popup)
	await popup.get_tree().process_frame

	var anchor := _anchor_above_dice(highlight_indices)
	popup.position = anchor - Vector2(popup.size.x * 0.5, popup.size.y + 8.0)

	var start_y := popup.position.y
	var tween := create_tween()
	tween.bind_node(popup)
	tween.set_parallel(true)
	tween.tween_property(popup, "position:y", start_y - POPUP_RISE, 0.45)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(popup, "modulate:a", 0.0, 0.45).set_delay(0.12)
	await tween.finished
	if is_instance_valid(popup):
		popup.queue_free()


func _anchor_above_dice(indices: Array[int]) -> Vector2:
	if indices.is_empty():
		return _popup_layer.size * 0.5

	var combined := Rect2()
	for idx in indices:
		var dice: Control = _dice_views[idx]
		var dice_rect := dice.get_global_rect()
		if combined.size == Vector2.ZERO:
			combined = dice_rect
		else:
			combined = combined.merge(dice_rect)

	var center_top_global := Vector2(
		combined.position.x + combined.size.x * 0.5,
		combined.position.y,
	)
	return _popup_layer.get_global_transform().affine_inverse() * center_top_global


func _clear_popups() -> void:
	for child in _popup_layer.get_children():
		if is_instance_valid(child):
			child.queue_free()


func _reset_score_board() -> void:
	_left_value.text = "0"
	_right_value.text = "0"
