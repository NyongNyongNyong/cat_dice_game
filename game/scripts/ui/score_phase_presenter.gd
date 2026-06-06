class_name ScorePhasePresenter
extends Node

const DICE_SCENE := preload("res://scenes/dice/dice.tscn")

const HAND_STEP_DELAY := 0.2
const NUMBER_STEP_DELAY := 0.04
const HAND_POPUP_DURATION := 0.55
const NUMBER_POPUP_DURATION := 0.28
const TIER_RESET_DELAY := 0.15
const POPUP_RISE := 32.0
const FOCUS_MOVE_DURATION := 0.22
const FOCUS_HOLD_DURATION := 0.16
const FOCUS_RETURN_DURATION := 0.2
const FOCUS_GAP := 10.0
const FOCUS_SCALE := Vector2(1.22, 1.22)

signal presentation_finished()

var _dice_row: Control
var _popup_layer: Control
var _dice_views: Array[Control] = []
var _left_value: Label
var _right_value: Label
var _status_label: Label
var _dice_values: Array[int] = []


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
	_dice_values = evaluation.dice_values.duplicate()

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
	_status_label.text = "숫자 합을 계산하는 중..."

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
	var prev_hand_id := ""
	var prev_highlight_indices: Array[int] = []
	_right_value.text = "0"
	_status_label.text = "족보를 계산하는 중..."

	for step in steps:
		var tier_changed := prev_hand_id != "" and step.hand_id != prev_hand_id
		if step.clear_before or tier_changed:
			_clear_highlights()
			if _highlights_overlap(prev_highlight_indices, step.highlight_indices):
				await get_tree().create_timer(TIER_RESET_DELAY).timeout
			else:
				await get_tree().process_frame

		prev_hand_id = step.hand_id
		prev_highlight_indices = step.highlight_indices.duplicate()
		_apply_highlights(step.highlight_indices)
		await _play_focus_dice(step.highlight_indices)
		hand_running += step.points_added
		_right_value.text = str(hand_running)
		await _show_hand_popup(step.display_ko, step.points_added, step.highlight_indices)
		await get_tree().create_timer(HAND_STEP_DELAY).timeout


func _highlights_overlap(previous: Array[int], next: Array[int]) -> bool:
	if previous.is_empty() or next.is_empty():
		return false

	var previous_set: Dictionary = {}
	for index in previous:
		previous_set[index] = true

	for index in next:
		if previous_set.has(index):
			return true

	return false


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


func _play_focus_dice(indices: Array[int]) -> void:
	if indices.is_empty():
		return

	var focus_items: Array[Dictionary] = []
	var seen_indices: Dictionary = {}
	for idx in indices:
		if idx < 0 or idx >= _dice_views.size() or idx >= _dice_values.size():
			continue
		if seen_indices.has(idx):
			continue
		seen_indices[idx] = true

		var original: Control = _dice_views[idx]
		var original_rect := original.get_global_rect()
		var local_position := _popup_layer.get_global_transform().affine_inverse() * original_rect.position
		var clone: Control = DICE_SCENE.instantiate()
		clone.mouse_filter = Control.MOUSE_FILTER_IGNORE
		clone.z_index = 8
		clone.position = local_position
		clone.size = original_rect.size
		clone.pivot_offset = original_rect.size * 0.5
		clone.set_value(_dice_values[idx])
		clone.set_dimmed(false)
		clone.set_highlighted(false)
		_popup_layer.add_child(clone)

		focus_items.append({
			"index": idx,
			"original": original,
			"clone": clone,
			"start_position": local_position,
			"size": original_rect.size,
		})

	if focus_items.is_empty():
		return

	for item in focus_items:
		var original: Control = item["original"]
		original.visible = false

	await _move_focus_items(focus_items, _target_positions_for_focus(focus_items))
	for item in focus_items:
		var clone: Control = item["clone"]
		clone.set_highlighted(true)

	await _pulse_focus_items(focus_items)
	await get_tree().create_timer(FOCUS_HOLD_DURATION).timeout
	await _return_focus_items(focus_items)

	for item in focus_items:
		var original: Control = item["original"]
		var clone: Control = item["clone"]
		original.visible = true
		if is_instance_valid(clone):
			clone.queue_free()


func _target_positions_for_focus(focus_items: Array[Dictionary]) -> Array[Vector2]:
	var target_positions: Array[Vector2] = []
	var item_count := focus_items.size()
	var dice_size: Vector2 = focus_items[0]["size"]
	var gap_count: int = maxi(0, item_count - 1)
	var total_width: float = dice_size.x * item_count + FOCUS_GAP * gap_count
	var start_x: float = (_popup_layer.size.x - total_width) * 0.5
	var target_y: float = (_popup_layer.size.y - dice_size.y) * 0.5

	for i in item_count:
		target_positions.append(Vector2(start_x + i * (dice_size.x + FOCUS_GAP), target_y))

	return target_positions


func _move_focus_items(focus_items: Array[Dictionary], target_positions: Array[Vector2]) -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	for i in focus_items.size():
		var clone: Control = focus_items[i]["clone"]
		tween.tween_property(clone, "position", target_positions[i], FOCUS_MOVE_DURATION)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished


func _pulse_focus_items(focus_items: Array[Dictionary]) -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	for item in focus_items:
		var clone: Control = item["clone"]
		tween.tween_property(clone, "scale", FOCUS_SCALE, FOCUS_HOLD_DURATION)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(clone, "scale", Vector2.ONE, FOCUS_HOLD_DURATION)\
			.set_delay(FOCUS_HOLD_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await tween.finished


func _return_focus_items(focus_items: Array[Dictionary]) -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	for item in focus_items:
		var clone: Control = item["clone"]
		clone.set_highlighted(false)
		tween.tween_property(clone, "position", item["start_position"], FOCUS_RETURN_DURATION)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await tween.finished


func _show_hand_popup(hand_name: String, points: int, highlight_indices: Array[int]) -> void:
	var popup := VBoxContainer.new()
	popup.add_theme_constant_override("separation", 2)
	popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup.z_index = 10

	var name_label := Label.new()
	name_label.text = hand_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 28)
	name_label.add_theme_color_override("font_color", Color(0.42, 0.28, 0.62, 1.0))
	name_label.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.95))
	name_label.add_theme_constant_override("outline_size", 4)
	popup.add_child(name_label)

	var points_label := Label.new()
	points_label.text = "+%d" % points
	points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	points_label.add_theme_font_size_override("font_size", 24)
	points_label.add_theme_color_override("font_color", Color(0.72, 0.42, 0.08, 1.0))
	points_label.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.9))
	points_label.add_theme_constant_override("outline_size", 4)
	popup.add_child(points_label)

	await _animate_popup(popup, highlight_indices, HAND_POPUP_DURATION)


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

	await _animate_popup(popup, highlight_indices, NUMBER_POPUP_DURATION)


func _animate_popup(popup: Control, highlight_indices: Array[int], duration: float) -> void:
	popup.modulate.a = 0.0
	_popup_layer.add_child(popup)
	await popup.get_tree().process_frame

	var anchor := _anchor_above_dice(highlight_indices)
	popup.position = anchor - Vector2(popup.size.x * 0.5, popup.size.y + 8.0)
	popup.modulate.a = 1.0

	var start_y := popup.position.y
	var tween := create_tween()
	tween.bind_node(popup)
	tween.set_parallel(true)
	tween.tween_property(popup, "position:y", start_y - POPUP_RISE, duration)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(popup, "modulate:a", 0.0, duration).set_delay(duration * 0.25)
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
