class_name GoldCalculator
extends RefCounted

const DEFAULT_THRESHOLD_RATIO := 2.0
const REROLL_GOLD_COST := 1


static func calculate_reward(
	final_chips: int,
	target_chips: int,
	threshold_ratio: float = DEFAULT_THRESHOLD_RATIO
) -> int:
	if target_chips <= 0 or final_chips < target_chips:
		return 0
	if threshold_ratio <= 1.0:
		return 1

	var ratio := float(final_chips) / float(target_chips)
	var steps := int(floor(log(ratio) / log(threshold_ratio))) + 1
	return int(steps * (steps + 1) / 2)
