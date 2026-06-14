extends Node

const DiceRosterScript := preload("res://scripts/core/dice_roster.gd")
const GoldCalculator := preload("res://scripts/core/gold_calculator.gd")
const ShopOfferService := preload("res://scripts/core/shop_offer_service.gd")

# hand-scoring-v2 playtest targets (Σ(숫자) × Σ(족보) 스케일)
const FLOOR_TARGETS: Array[int] = [10, 20, 40, 80, 160]
const MAX_FLOOR: int = 5
const DICE_COUNT: int = 10
const INITIAL_CHIPS: int = 10

var current_floor: int = 1
var target_score: int = 10
var current_score: int = 0
var chips: int = 0
var gold: int = 0
var run_finished: bool = false
var shop_entry_gold_earned: int = 0
var _dice_roster: RefCounted

signal floor_changed(floor: int, target: int)
signal score_changed(score: int)
signal chips_changed(chips: int)
signal gold_changed(gold: int)
signal run_completed()
signal roster_changed()


func start_run() -> void:
	run_finished = false
	current_floor = 1
	current_score = 0
	chips = INITIAL_CHIPS
	gold = 0
	_dice_roster = DiceRosterScript.new()
	_dice_roster.reset_to_starting()
	roster_changed.emit()
	_apply_floor_target()


func reset_floor_round() -> void:
	current_score = 0
	chips = INITIAL_CHIPS
	score_changed.emit(current_score)
	chips_changed.emit(chips)


func set_score(score: int) -> void:
	current_score = score
	score_changed.emit(current_score)


func add_score(amount: int) -> void:
	current_score += maxi(amount, 0)
	score_changed.emit(current_score)


func can_spend_chip() -> bool:
	return not run_finished and chips > 0


func try_spend_chip() -> bool:
	if not can_spend_chip():
		return false
	chips -= 1
	chips_changed.emit(chips)
	return true


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


func is_run_started() -> bool:
	return _dice_roster != null


func enter_shop() -> void:
	shop_entry_gold_earned = collect_round_gold()


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
	shop_entry_gold_earned = 0
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


func swap_owned_dice(first_index: int, second_index: int) -> bool:
	if _dice_roster == null:
		return false
	if not _dice_roster.swap_indices(first_index, second_index):
		return false
	roster_changed.emit()
	return true


func get_shop_offers() -> Array[Dictionary]:
	return ShopOfferService.shared().get_offers()


func get_shop_offer_price(dice_id: String) -> int:
	return ShopOfferService.shared().get_price(dice_id)


func can_afford_shop_offer(dice_id: String) -> bool:
	return gold >= get_shop_offer_price(dice_id)


func try_purchase_shop_replace(dice_id: String, slot_index: int) -> bool:
	if _dice_roster == null:
		return false

	var price: int = get_shop_offer_price(dice_id)
	if price <= 0 or gold < price:
		return false
	if get_shop_offer(dice_id).is_empty():
		return false
	if not replace_owned_dice_at(slot_index, dice_id):
		return false

	gold -= price
	gold_changed.emit(gold)
	return true


func get_shop_offer(dice_id: String) -> Dictionary:
	return ShopOfferService.shared().get_offer(dice_id)


func _apply_floor_target() -> void:
	target_score = FLOOR_TARGETS[current_floor - 1]
	floor_changed.emit(current_floor, target_score)
	score_changed.emit(current_score)
	chips_changed.emit(chips)
