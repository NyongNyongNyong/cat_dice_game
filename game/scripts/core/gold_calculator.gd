class_name GoldCalculator
extends RefCounted

const DEFAULT_INTERVAL_RATIO := 0.5
const REROLL_GOLD_COST := 1


static func calculate_reward(
	final_chips: int,
	target_chips: int,
	interval_ratio: float = DEFAULT_INTERVAL_RATIO
) -> int:
	if target_chips <= 0 or final_chips < target_chips:
		return 0

	var interval := int(floor(float(target_chips) * interval_ratio))
	if interval <= 0:
		return 1

	var excess := final_chips - target_chips
	var tiers := int(floor(float(excess) / float(interval)))
	return _gold_for_tiers(tiers)


static func _gold_for_tiers(tiers: int) -> int:
	var steps := tiers + 1
	return int(steps * (steps + 1) / 2)
