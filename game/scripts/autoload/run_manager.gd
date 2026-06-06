extends Node

# hand-scoring-v2 playtest targets (Σ(숫자) × Σ(족보) 스케일)
const FLOOR_TARGETS: Array[int] = [150, 350, 600, 1000, 1600]
const MAX_FLOOR: int = 5
const DICE_COUNT: int = 10

var current_floor: int = 1
var target_score: int = 150
var current_score: int = 0
var run_finished: bool = false

signal floor_changed(floor: int, target: int)
signal score_changed(score: int)
signal run_completed()


func start_run() -> void:
	run_finished = false
	current_floor = 1
	current_score = 0
	_apply_floor_target()


func reset_floor_round() -> void:
	current_score = 0
	score_changed.emit(current_score)


func set_score(score: int) -> void:
	current_score = score
	score_changed.emit(current_score)


func can_advance_floor() -> bool:
	return not run_finished and current_score >= target_score


func advance_floor() -> void:
	if not can_advance_floor():
		return

	if current_floor >= MAX_FLOOR:
		run_finished = true
		run_completed.emit()
		return

	current_floor += 1
	reset_floor_round()
	_apply_floor_target()


func _apply_floor_target() -> void:
	target_score = FLOOR_TARGETS[current_floor - 1]
	floor_changed.emit(current_floor, target_score)
	score_changed.emit(current_score)
