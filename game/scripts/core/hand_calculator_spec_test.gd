extends SceneTree

var _failed := 0


func _init() -> void:
	# Pachinko-chip-flow: activate only the single highest-value hand once.
	_expect_hand_sum([1, 1, 2, 2], 5, "1122 best pair stair")
	_expect_hand_sum([1, 1, 1, 1, 1], 16, "11111 best penta")
	_expect_hand_sum([1, 2, 3, 4, 5, 6], 16, "123456 best straight")
	_expect_hand_sum([1, 1, 2, 2, 3, 3, 4, 4, 5, 5], 30, "1122334455 best stair")
	_expect_hand_sum([1, 2, 3, 4], 1, "1234 default multiplier")

	_expect_hand_count([1, 2, 3, 4, 5, 6], "straight_6", 1, "123456 straight")
	_expect_hand_count([1, 1, 2, 2, 3, 3, 4, 4, 5, 5], "straight_5", 0, "1122334455 straight")
	_expect_hand_count([1, 1, 2, 2, 3, 3, 4, 4, 5, 5], "pair_stair_5", 1, "1122334455 stair")

	_expect_hand_count([1, 1, 1, 2, 2], "full_house", 1, "11122 full house")
	_expect_hand_count([1, 1, 1, 2, 2, 2, 3, 3, 4, 4], "full_house", 0, "1112223344 full house")
	_expect_hand_count([3, 4, 3, 3, 4, 6, 2, 1, 4, 5], "full_house", 0, "3433462145 full house")

	_expect_summary([1, 1, 3, 3], [
		{"hand_id": "two_pair", "count": 1},
	], "1133 active hands")

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


func _expect_summary(values: Array[int], expected_rows: Array, label: String) -> void:
	var summaries := HandCalculator.summarize_steps(HandCalculator.evaluate(values).steps)
	if summaries.size() != expected_rows.size():
		_failed += 1
		push_error(
			"%s: summary size expected %d got %d" % [label, expected_rows.size(), summaries.size()]
		)
		return

	for i in expected_rows.size():
		var row: Dictionary = expected_rows[i]
		var got: Dictionary = summaries[i]
		if got.get("hand_id") != row.get("hand_id") or int(got.get("count")) != int(row.get("count")):
			_failed += 1
			push_error(
				"%s: row %d expected %s got %s" % [label, i, str(row), str(got)]
			)
