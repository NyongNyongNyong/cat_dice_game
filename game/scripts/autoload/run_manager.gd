extends Node

const DiceRosterScript := preload("res://scripts/core/dice_roster.gd")
const GoldCalculator := preload("res://scripts/core/gold_calculator.gd")

# hand-scoring-v2 playtest targets (Σ(숫자) × Σ(족보) 스케일)
const FLOOR_TARGETS: Array[int] = [5, 5, 5, 5, 5]
const MAX_FLOOR: int = 5
const DICE_COUNT: int = 10

var current_floor: int = 1
var target_score: int = 5
var current_score: int = 0
var gold: int = 0
var run_finished: bool = false
var _dice_roster: RefCounted

signal floor_changed(floor: int, target: int)
signal score_changed(score: int)
signal gold_changed(gold: int)
signal run_completed()
signal roster_changed()


func start_run() -> void:
	run_finished = false
	current_floor = 1
	current_score = 0
	gold = 0
	_dice_roster = DiceRosterScript.new()
	_dice_roster.reset_to_starting()
	roster_changed.emit()
	_apply_floor_target()


func reset_floor_round() -> void:
	current_score = 0
	score_changed.emit(current_score)


func set_score(score: int) -> void:
	current_score = score
	score_changed.emit(current_score)


func can_advance_floor() -> bool:
	return not run_finished and current_score >= target_score


func has_met_chip_target() -> bool:
	return current_score >= target_score


func can_afford_reroll() -> bool:
	if not has_met_chip_target():
		return true
	return gold >= GoldCalculator.REROLL_GOLD_COST


func try_spend_reroll_gold() -> bool:
	if not has_met_chip_target():
		return true
	if gold < GoldCalculator.REROLL_GOLD_COST:
		return false
	gold -= GoldCalculator.REROLL_GOLD_COST
	gold_changed.emit(gold)
	return true


func collect_round_gold() -> int:
	var earned: int = GoldCalculator.calculate_reward(current_score, target_score)
	if earned <= 0:
		return 0
	gold += earned
	gold_changed.emit(gold)
	return earned


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


func get_dice_roster() -> RefCounted:
	return _dice_roster


func get_owned_dice() -> Array[Resource]:
	if _dice_roster == null:
		return []
	return _dice_roster.get_owned_dice()


func get_owned_dice_count() -> int:
	if _dice_roster == null:
		return 0
	return _dice_roster.get_count()


func replace_owned_dice_at(slot_index: int, dice_id: String) -> bool:
	if _dice_roster == null:
		return false
	if not _dice_roster.replace_at_index(slot_index, dice_id):
		return false
	roster_changed.emit()
	return true


func get_shop_replace_offer_id() -> String:
	if _dice_roster == null:
		return "dice_triple_h"
	return _dice_roster.get_shop_replace_offer_id()


func _apply_floor_target() -> void:
	target_score = FLOOR_TARGETS[current_floor - 1]
	floor_changed.emit(current_floor, target_score)
	score_changed.emit(current_score)
