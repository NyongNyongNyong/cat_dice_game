extends SceneTree

const GoldCalculatorScript := preload("res://scripts/core/gold_calculator.gd")

var _failed := 0

const T5 := 5


func _init() -> void:
	_expect_reward(4, T5, 0)
	_expect_reward(5, T5, 1)
	_expect_reward(9, T5, 1)
	_expect_reward(10, T5, 3)
	_expect_reward(19, T5, 3)
	_expect_reward(20, T5, 6)
	_expect_reward(40, T5, 10)
	_expect_reward(80, T5, 15)
	_expect_reward(160, T5, 21)
	_expect_reward(90, 10, 10)

	if _failed > 0:
		push_error("Gold calculator spec tests failed: %d" % _failed)
	quit(_failed)


func _expect_reward(final_chips: int, target_chips: int, expected: int) -> void:
	var got: int = GoldCalculatorScript.calculate_reward(final_chips, target_chips)
	if got != expected:
		_fail("S=%d T=%d" % [final_chips, target_chips], expected, got)


func _fail(label: String, expected: int, got: int) -> void:
	_failed += 1
	push_error("%s: expected %d got %d" % [label, expected, got])
