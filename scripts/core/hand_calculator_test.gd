extends SceneTree

const HandCalculator := preload("res://scripts/core/hand_calculator.gd")


func _init() -> void:
	_test([1, 1, 2, 2], "1122")
	_test([1, 1, 1, 1, 1], "11111")
	_test([1, 1, 2, 2, 3, 3, 4, 4, 5, 5], "1122334455")
	_test([1, 2, 3, 4, 5, 6], "123456")
	_test([1, 2, 3, 4, 5, 2, 3, 4, 5, 6], "1234523456")
	quit()


func _test(values: Array[int], name: String) -> void:
	var eval := HandCalculator.evaluate(values)
	print("%s sum=%d hand=%d total=%d steps=%d" % [
		name, eval.number_sum, eval.hand_value_sum, eval.total_score, eval.steps.size(),
	])
	for step in eval.steps:
		print("  %s +%d" % [step.display_ko, step.points_added])
