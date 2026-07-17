extends SceneTree

const RunManagerScript := preload("res://scripts/autoload/run_manager.gd")
const CatalogService := preload("res://scripts/core/dice_catalog_service.gd")

var _failed := 0


func _init() -> void:
	CatalogService.reset_for_tests()
	_test_add_dice()
	_test_purchase_batch_add()
	_test_purchase_batch_replace()
	_test_reject_when_insufficient_gold()
	_test_reject_over_capacity()

	if _failed > 0:
		push_error("Shop purchase spec tests failed: %d" % _failed)
	quit(_failed)


func _fresh_run(gold: int) -> Node:
	var rm: Node = RunManagerScript.new()
	rm.start_run()
	rm.gold = gold
	return rm


func _test_add_dice() -> void:
	var rm := _fresh_run(0)
	var before: int = rm.get_owned_dice_count()
	_expect(rm.add_owned_dice("dice_triple_luck"), "add_owned_dice succeeds")
	_expect(rm.get_owned_dice_count() == before + 1, "owned count grew by 1")
	rm.free()


func _test_purchase_batch_add() -> void:
	var rm := _fresh_run(10)
	var before: int = rm.get_owned_dice_count()
	var entries: Array = [
		{"action": "add", "slot": before, "dice_id": "dice_triple_luck"},
	]
	_expect(rm.purchase_dice_batch(entries), "batch add succeeds")
	_expect(rm.get_owned_dice_count() == before + 1, "batch add grew roster")
	_expect(rm.gold == 10 - rm.SHOP_DICE_PRICE, "batch add spent price")
	rm.free()


func _test_purchase_batch_replace() -> void:
	var rm := _fresh_run(10)
	var count: int = rm.get_owned_dice_count()
	var entries: Array = [
		{"action": "replace", "slot": 0, "dice_id": "dice_triple_luck"},
	]
	_expect(rm.purchase_dice_batch(entries), "batch replace succeeds")
	_expect(rm.get_owned_dice_count() == count, "replace keeps count")
	var first: Resource = rm.get_owned_dice()[0]
	_expect(str(first.id) == "dice_triple_luck", "slot 0 replaced")
	_expect(rm.gold == 10 - rm.SHOP_DICE_PRICE, "replace spent price")
	rm.free()


func _test_reject_when_insufficient_gold() -> void:
	var rm := _fresh_run(2)
	var entries: Array = [
		{"action": "add", "slot": 4, "dice_id": "dice_triple_luck"},
	]
	_expect(not rm.purchase_dice_batch(entries), "reject when gold < cost")
	_expect(rm.gold == 2, "gold unchanged on reject")
	rm.free()


func _test_reject_over_capacity() -> void:
	var rm := _fresh_run(100)
	# 시작 4개 → 최대 8개. 5개 추가는 용량 초과.
	var entries: Array = []
	for i in 5:
		entries.append({"action": "add", "slot": 4 + i, "dice_id": "dice_basic"})
	_expect(not rm.purchase_dice_batch(entries), "reject when over MAX_OWNED_DICE")
	rm.free()


func _expect(condition: bool, label: String) -> void:
	if not condition:
		_failed += 1
		push_error("shop purchase: %s" % label)
