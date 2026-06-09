extends SceneTree

const GoldCalculatorScript := preload("res://scripts/core/gold_calculator.gd")

var _failed := 0


func _init() -> void:
	_expect_reward(100, 100, 100, 1)
	_expect_reward(149, 100, 100, 1)
	_expect_reward(150, 100, 100, 3)
	_expect_reward(199, 100, 100, 3)
	_expect_reward(200, 100, 100, 6)
	_expect_reward(249, 100, 100, 6)
	_expect_reward(250, 100, 100, 10)
	_expect_reward(300, 100, 100, 15)
	_expect_reward(350, 100, 100, 21)
	_expect_reward(99, 100, 100, 0)
	_expect_reward(100, 0, 100, 0)

	if _failed > 0:
		push_error("Gold calculator spec tests failed: %d" % _failed)
	quit(_failed)


func _expect_reward(final_chips: int, target_chips: int, _label: int, expected: int) -> void:
	var got := GoldCalculatorScript.calculate_reward(final_chips, target_chips)
	if got != expected:
		_fail("S=%d T=%d" % [final_chips, target_chips], expected, got)


func _fail(label: String, expected: int, got: int) -> void:
	_failed += 1
	push_error("%s: expected %d got %d" % [label, expected, got])
