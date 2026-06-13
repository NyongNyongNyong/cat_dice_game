class_name ScorePhasePresenter
extends Node

const DICE_SCENE := preload("res://scenes/dice/dice.tscn")

const NUMBER_STEP_DELAY := 0.04
const NUMBER_POPUP_DURATION := 0.28
const REROLL_HAND_STEP_DELAY := 0.02
const REROLL_HAND_POPUP_DURATION := 0.18
const REROLL_FOCUS_MOVE_DURATION := 0.08
const REROLL_FOCUS_HOLD_DURATION := 0.05
const REROLL_FOCUS_RETURN_DURATION := 0.08
const REROLL_REVEAL_HOLD := 0.06
const POPUP_RISE := 32.0
const FOCUS_GAP := 10.0
const FOCUS_SCALE := Vector2(1.22, 1.22)

var _hand_step_delay := NUMBER_STEP_DELAY
var _hand_popup_duration := NUMBER_POPUP_DURATION
var _focus_move_duration := 0.1
var _focus_hold_duration := 0.08
var _focus_return_duration := 0.1

signal presentation_finished()

var _dice_row: Control
var _popup_layer: Control
var _dice_views: Array[Control] = []
var _left_value: Label
var _right_value: Label
var _status_label: Label
var _active_hands_presenter: Node
var _dice_values: Array[int] = []
var _dice_faces: Array = []
var _hand_steps_seen: Array[HandStep] = []


func setup(
	dice_row: Control,
	popup_layer: Control,
	left_value: Label,
	right_value: Label,
	status_label: Label,
	active_hands_presenter: Node = null,
) -> void:
	_dice_row = dice_row
	_popup_layer = popup_layer
	_left_value = left_value
	_right_value = right_value
	_status_label = status_label
	_active_hands_presenter = active_hands_presenter


func set_dice_views(dice_views: Array[Control]) -> void:
	_dice_views = dice_views


func play(
	evaluation: HandEvaluation,
	hands_only: bool = false,
	rerolled_die_index: int = -1,
	dice_faces: Array = [],
) -> void:
	_dice_row.visible = true
	_clear_popups()
	_apply_timing_profile(hands_only)
	_dice_values = evaluation.dice_values.duplicate()
	_dice_faces = dice_faces.duplicate()

	if hands_only:
		for dice in _dice_views:
			dice.set_dimmed(true)
	else:
		for dice in _dice_views:
			dice.show_placeholder()
		for i in evaluation.dice_values.size():
			_apply_face_to_view(i, evaluation.dice_values[i])
			_dice_views[i].set_dimmed(true)

	if hands_only:
		_prepare_hand_reroll_board(evaluation)
		if rerolled_die_index >= 0:
			await _play_reroll_reveal(rerolled_die_index)
		await _play_hand_steps(evaluation.steps, true)
	else:
		_reset_score_board()
		await _play_number_sum(evaluation.dice_values)
		await _play_hand_steps(evaluation.steps, false)

	_clear_highlights()
	_clear_popups()
	_restore_all_dice_faces()
	presentation_finished.emit()


func _apply_timing_profile(hands_only: bool) -> void:
	if hands_only:
		_hand_step_delay = REROLL_HAND_STEP_DELAY
		_hand_popup_duration = REROLL_HAND_POPUP_DURATION
		_focus_move_duration = REROLL_FOCUS_MOVE_DURATION
		_focus_hold_duration = REROLL_FOCUS_HOLD_DURATION
		_focus_return_duration = REROLL_FOCUS_RETURN_DURATION
	else:
		_hand_step_delay = NUMBER_STEP_DELAY
		_hand_popup_duration = NUMBER_POPUP_DURATION
		_focus_move_duration = 0.1
		_focus_hold_duration = 0.08
		_focus_return_duration = 0.1


func _prepare_hand_reroll_board(evaluation: HandEvaluation) -> void:
	_left_value.text = str(evaluation.number_sum)
	_right_value.text = "0"
	_reset_active_hands_list()


func _play_reroll_reveal(die_index: int) -> void:
	if die_index < 0 or die_index >= _dice_views.size():
		return

	_status_label.text = "리롤 결과"
	_clear_highlights()
	for i in _dice_views.size():
		_dice_views[i].set_dimmed(i != die_index)
	var rerolled: Control = _dice_views[die_index]
	rerolled.set_highlighted(true)
	await _pulse_dice_in_place([rerolled])
	await get_tree().create_timer(REROLL_REVEAL_HOLD).timeout

	for dice in _dice_views:
		dice.set_highlighted(false)
		dice.set_dimmed(true)


func _apply_face_to_view(index: int, resolved_value: int) -> void:
	if index >= _dice_views.size():
		return
	if index < _dice_faces.size() and _dice_faces[index] != null:
		_dice_views[index].set_face(_dice_faces[index], resolved_value)


func _apply_face_to_dice(dice: Control, index: int) -> void:
	if index < _dice_faces.size() and _dice_faces[index] != null:
		dice.set_face(_dice_faces[index], _dice_values[index])


func _restore_all_dice_faces() -> void:
	for i in _dice_values.size():
		_apply_face_to_view(i, _dice_values[i])


func _pulse_dice_in_place(dice_views: Array) -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	for dice in dice_views:
		dice.pivot_offset = dice.size * 0.5
		tween.tween_property(dice, "scale", FOCUS_SCALE, _focus_hold_duration)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(dice, "scale", Vector2.ONE, _focus_hold_duration)\
			.set_delay(_focus_hold_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await tween.finished
	for dice in dice_views:
		if is_instance_valid(dice):
			dice.scale = Vector2.ONE
			dice.pivot_offset = Vector2.ZERO


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
		await _show_points_popup("+%d" % values[i], [i], NUMBER_POPUP_DURATION)
		await get_tree().create_timer(NUMBER_STEP_DELAY).timeout

	_clear_highlights()
	for dice in _dice_views:
		dice.set_dimmed(true)


func _play_hand_steps(steps: Array[HandStep], reroll: bool) -> void:
	var hand_running := 0
	if not reroll:
		_right_value.text = "0"
	_reset_active_hands_list()
	_status_label.text = "족보를 다시 계산하는 중..." if reroll else "족보를 계산하는 중..."

	for step in steps:
		_apply_highlights(step.highlight_indices)
		await _play_focus_dice(step.highlight_indices)
		hand_running += step.points_added
		_right_value.text = str(hand_running)
		_append_active_hand_step(step)
		await _show_hand_popup(step.display_ko, step.points_added, step.highlight_indices)
		await get_tree().create_timer(_hand_step_delay).timeout


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
		_apply_face_to_dice(clone, idx)
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
		_hide_dice_for_focus(item["original"])

	await _move_focus_items(focus_items, _target_positions_for_focus(focus_items))
	for item in focus_items:
		var clone: Control = item["clone"]
		clone.set_highlighted(true)

	await _pulse_focus_items(focus_items)
	await get_tree().create_timer(_focus_hold_duration).timeout
	await _return_focus_items(focus_items)

	for item in focus_items:
		_show_dice_after_focus(item["original"], item["index"])
		var clone: Control = item["clone"]
		if is_instance_valid(clone):
			clone.queue_free()


func _hide_dice_for_focus(dice: Control) -> void:
	# visible=false면 HBox가 재배치되어 나머지 주사위 위치가 흔들린다. 슬롯은 유지하고 투명 처리만 한다.
	dice.modulate.a = 0.0
	dice.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _show_dice_after_focus(dice: Control, index: int) -> void:
	dice.modulate.a = 1.0
	dice.mouse_filter = Control.MOUSE_FILTER_STOP
	_apply_face_to_dice(dice, index)


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
		tween.tween_property(clone, "position", target_positions[i], _focus_move_duration)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished


func _pulse_focus_items(focus_items: Array[Dictionary]) -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	for item in focus_items:
		var clone: Control = item["clone"]
		tween.tween_property(clone, "scale", FOCUS_SCALE, _focus_hold_duration)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(clone, "scale", Vector2.ONE, _focus_hold_duration)\
			.set_delay(_focus_hold_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await tween.finished


func _return_focus_items(focus_items: Array[Dictionary]) -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	for item in focus_items:
		var clone: Control = item["clone"]
		clone.set_highlighted(false)
		tween.tween_property(clone, "position", item["start_position"], _focus_return_duration)\
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

	await _animate_popup(popup, highlight_indices, _hand_popup_duration)


func _show_points_popup(text: String, highlight_indices: Array[int], duration: float = NUMBER_POPUP_DURATION) -> void:
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

	await _animate_popup(popup, highlight_indices, duration)


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
	_reset_active_hands_list()


func clear_active_hands() -> void:
	_reset_active_hands_list()


func _reset_active_hands_list() -> void:
	_hand_steps_seen.clear()
	if _active_hands_presenter != null and _active_hands_presenter.has_method("clear"):
		_active_hands_presenter.clear()


func _append_active_hand_step(step: HandStep) -> void:
	_hand_steps_seen.append(step)
	if _active_hands_presenter == null or not _active_hands_presenter.has_method("show_summaries"):
		return
	_active_hands_presenter.show_summaries(HandCalculator.summarize_steps(_hand_steps_seen))
