class_name RoundController
extends Node

signal phase_changed(phase: RoundPhase.Phase)
signal dice_rolled(values: Array[int])
signal die_selected(index: int)
signal die_rerolled(values: Array[int])
signal score_ready(evaluation: HandEvaluation)
signal round_reset()

var phase: RoundPhase.Phase = RoundPhase.Phase.IDLE
var dice_values: Array[int] = []
var hand_evaluation: HandEvaluation
var selected_die_index: int = -1


func begin_round() -> void:
	reset_round()


func reset_round() -> void:
	phase = RoundPhase.Phase.IDLE
	dice_values.clear()
	hand_evaluation = null
	selected_die_index = -1
	phase_changed.emit(phase)
	round_reset.emit()


func can_roll() -> bool:
	if phase == RoundPhase.Phase.IDLE:
		return true
	if phase == RoundPhase.Phase.REROLL_READY:
		return selected_die_index >= 0
	return false


func can_reroll_preview() -> bool:
	return phase == RoundPhase.Phase.REROLL_READY


func can_advance_floor() -> bool:
	return phase == RoundPhase.Phase.REROLL_READY


func roll() -> void:
	if phase == RoundPhase.Phase.IDLE:
		_roll_all_dice()
	elif phase == RoundPhase.Phase.REROLL_READY:
		_reroll_selected_die()


func select_die(index: int) -> void:
	if not can_reroll_preview():
		return
	if index < 0 or index >= dice_values.size():
		return

	selected_die_index = index
	die_selected.emit(index)


func clear_selection() -> void:
	selected_die_index = -1


func complete_roll_presentation() -> void:
	if phase != RoundPhase.Phase.ROLLING:
		return
	_begin_scoring()


func complete_score_presentation() -> void:
	if phase != RoundPhase.Phase.SCORING:
		return
	_set_phase(RoundPhase.Phase.REROLL_READY)


func _roll_all_dice() -> void:
	_set_phase(RoundPhase.Phase.ROLLING)
	selected_die_index = -1
	dice_values = _roll_dice_values()
	dice_rolled.emit(dice_values)


func _reroll_selected_die() -> void:
	if selected_die_index < 0 or selected_die_index >= dice_values.size():
		return

	dice_values[selected_die_index] = randi_range(1, 6)
	selected_die_index = -1
	die_rerolled.emit(dice_values)
	_begin_scoring()


func _begin_scoring() -> void:
	_set_phase(RoundPhase.Phase.SCORING)
	hand_evaluation = HandCalculator.evaluate(dice_values)
	score_ready.emit(hand_evaluation)


func _roll_dice_values() -> Array[int]:
	var values: Array[int] = []
	for _i in RunManager.DICE_COUNT:
		values.append(randi_range(1, 6))
	return values


func _set_phase(next_phase: RoundPhase.Phase) -> void:
	phase = next_phase
	phase_changed.emit(phase)
