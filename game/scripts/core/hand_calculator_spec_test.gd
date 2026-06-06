extends SceneTree

var _failed := 0


func _init() -> void:
	# hand-scoring-v2.md documented examples
	_expect_hand_sum([1, 1, 2, 2], 9, "1122 §3")
	_expect_hand_sum([1, 1, 1, 1, 1], 31, "11111 §2.1")
	_expect_hand_sum([1, 2, 3, 4, 5, 6], 16, "123456 §8.3")
	_expect_hand_sum([1, 1, 2, 2, 3, 3, 4, 4, 5, 5], 77, "1122334455 §8.3/§12")

	_expect_hand_count([1, 2, 3, 4, 5, 6], "straight_6", 1, "123456 straight")
	_expect_hand_count([1, 1, 2, 2, 3, 3, 4, 4, 5, 5], "straight_5", 2, "1122334455 straight")
	_expect_hand_count([1, 1, 2, 2, 3, 3, 4, 4, 5, 5], "pair_stair_5", 1, "1122334455 stair")

	# hand-scoring-v2.md §9 Full House
	_expect_hand_count([1, 1, 1, 2, 2], "full_house", 1, "11122 full house")
	_expect_hand_count([1, 1, 1, 2, 2, 2, 3, 3, 4, 4], "full_house", 2, "1112223344 full house")
	_expect_hand_count([3, 4, 3, 3, 4, 6, 2, 1, 4, 5], "full_house", 1, "3433462145 full house")

	if _failed > 0:
		push_error("Spec tests failed: %d" % _failed)
	quit(_failed)


func _expect_hand_sum(values: Array[int], expected: int, label: String) -> void:
	var eval := HandCalculator.evaluate(values)
	if eval.hand_value_sum != expected:
		_failed += 1
		push_error("%s: hand_value_sum expected %d got %d" % [label, expected, eval.hand_value_sum])


func _expect_hand_count(values: Array[int], hand_id: String, expected: int, label: String) -> void:
	var eval := HandCalculator.evaluate(values)
	var count := 0
	for step in eval.steps:
		if step.hand_id == hand_id:
			count += 1
	if count != expected:
		_failed += 1
		push_error("%s: %s count expected %d got %d" % [label, hand_id, expected, count])
