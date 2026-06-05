class_name RoundController
extends Node

signal phase_changed(phase: RoundPhase.Phase)
signal dice_rolled(values: Array[int])
signal score_ready(evaluation: HandEvaluation)
signal round_reset()

var phase: RoundPhase.Phase = RoundPhase.Phase.IDLE
var dice_values: Array[int] = []
var hand_evaluation: HandEvaluation


func begin_round() -> void:
	reset_round()


func reset_round() -> void:
	phase = RoundPhase.Phase.IDLE
	dice_values.clear()
	hand_evaluation = null
	phase_changed.emit(phase)
	round_reset.emit()


func can_roll() -> bool:
	return phase == RoundPhase.Phase.IDLE


func can_advance_floor() -> bool:
	return phase == RoundPhase.Phase.RESOLVED


func roll() -> void:
	if not can_roll():
		return

	_set_phase(RoundPhase.Phase.ROLLING)
	dice_values = _roll_dice_values()
	dice_rolled.emit(dice_values)


func complete_roll_presentation() -> void:
	if phase != RoundPhase.Phase.ROLLING:
		return
	_begin_scoring()


func complete_score_presentation() -> void:
	if phase != RoundPhase.Phase.SCORING:
		return
	_set_phase(RoundPhase.Phase.RESOLVED)


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
