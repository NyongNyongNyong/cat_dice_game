class_name RollPhasePresenter
extends Node

## Roll phase presenter. v0.1 cycles visible faces; replace this node for richer dice motion later.

const ROLL_DURATION := 0.6
const FACE_STEP_INTERVAL := 0.055
const ROLL_SETTLE_SCALE := Vector2(1.08, 1.08)
const ROLL_SETTLE_DURATION := 0.08

var _dice_row: Control
var _dice_views: Array[Control] = []
var _rng := RandomNumberGenerator.new()
var _speed_multiplier := 1.0


func setup(dice_row: Control) -> void:
	_dice_row = dice_row
	_rng.randomize()


func set_dice_views(dice_views: Array[Control]) -> void:
	_dice_views = dice_views


func set_speed_multiplier(multiplier: float) -> void:
	_speed_multiplier = maxf(multiplier, 1.0)


func play_roll(
	final_faces: Array,
	final_values: Array[int],
	candidate_faces_by_die: Array,
) -> void:
	var dice_indices: Array[int] = []
	for i in _dice_views.size():
		dice_indices.append(i)
	await _play_face_cycle(dice_indices, final_faces, final_values, candidate_faces_by_die, _scaled_duration(ROLL_DURATION))


func _play_face_cycle(
	dice_indices: Array[int],
	final_faces: Array,
	final_values: Array[int],
	candidate_faces_by_die: Array,
	duration: float,
) -> void:
	_dice_row.visible = true
	if dice_indices.is_empty():
		return

	var elapsed := 0.0
	while elapsed < duration:
		for dice_index in dice_indices:
			_apply_random_candidate_face(dice_index, final_values, candidate_faces_by_die)
		var step_interval := _scaled_duration(FACE_STEP_INTERVAL)
		await get_tree().create_timer(step_interval).timeout
		elapsed += step_interval

	_apply_final_faces(dice_indices, final_faces, final_values)
	await _play_settle(dice_indices)


func _apply_random_candidate_face(
	dice_index: int,
	final_values: Array[int],
	candidate_faces_by_die: Array,
) -> void:
	if dice_index < 0 or dice_index >= _dice_views.size():
		return
	var candidates := _get_candidate_faces(dice_index, candidate_faces_by_die)
	if candidates.is_empty():
		_dice_views[dice_index].show_placeholder()
		return

	var face: Resource = candidates[_rng.randi_range(0, candidates.size() - 1)]
	var resolved_value := _get_preview_value(face, final_values, dice_index)
	_dice_views[dice_index].set_face(face, resolved_value)


func _get_candidate_faces(dice_index: int, candidate_faces_by_die: Array) -> Array:
	if dice_index < 0 or dice_index >= candidate_faces_by_die.size():
		return []
	var candidates = candidate_faces_by_die[dice_index]
	if typeof(candidates) != TYPE_ARRAY:
		return []
	return candidates


func _get_preview_value(face: Resource, final_values: Array[int], dice_index: int) -> int:
	if face != null and face.has_method("is_number") and face.is_number():
		return face.get_base_number_value()
	if dice_index >= 0 and dice_index < final_values.size():
		return final_values[dice_index]
	return 1


func _apply_final_faces(dice_indices: Array[int], final_faces: Array, final_values: Array[int]) -> void:
	for dice_index in dice_indices:
		if dice_index < 0 or dice_index >= _dice_views.size():
			continue
		if dice_index >= final_faces.size() or dice_index >= final_values.size():
			continue
		var face: Resource = final_faces[dice_index]
		if face == null:
			_dice_views[dice_index].show_placeholder()
			continue
		_dice_views[dice_index].set_face(face, final_values[dice_index])


func _play_settle(dice_indices: Array[int]) -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	for dice_index in dice_indices:
		if dice_index < 0 or dice_index >= _dice_views.size():
			continue
		var dice := _dice_views[dice_index]
		dice.pivot_offset = dice.size * 0.5
		var settle_duration := _scaled_duration(ROLL_SETTLE_DURATION)
		tween.tween_property(dice, "scale", ROLL_SETTLE_SCALE, settle_duration)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(dice, "scale", Vector2.ONE, settle_duration)\
			.set_delay(settle_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await tween.finished

	for dice_index in dice_indices:
		if dice_index >= 0 and dice_index < _dice_views.size():
			_dice_views[dice_index].scale = Vector2.ONE
			_dice_views[dice_index].pivot_offset = Vector2.ZERO


func _scaled_duration(duration: float) -> float:
	return maxf(duration / _speed_multiplier, 0.01)
