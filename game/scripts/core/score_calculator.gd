class_name ScoreCalculator

const HandCalculator := preload("res://scripts/core/hand_calculator.gd")


static func sum_numbers(dice_values: Array) -> int:
	var total := 0
	for face in dice_values:
		total += int(face)
	return total


static func calculate_total_score(dice_values: Array) -> int:
	var evaluation := HandCalculator.evaluate(dice_values)
	return evaluation.total_score
