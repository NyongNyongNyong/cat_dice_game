class_name GoldCalculator
extends RefCounted

const DEFAULT_THRESHOLD_RATIO := 2.0
const REROLL_GOLD_COST := 1
const MAX_THRESHOLD_SEGMENTS := 24


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


# --- 임계 구간 ---------------------------------------------------------------
# 목표 점수를 배수로 넘길 때마다 새 구간이 열린다. 진행 바 표시와 오버킬 골드가
# 같은 임계값을 쓰므로 구간 계산을 여기에 둔다. 각 구간은
# {index, lower, upper, max_value, value} 형태.

static func build_threshold_segments(
	score: int,
	target_score: int,
	threshold_ratio: float = DEFAULT_THRESHOLD_RATIO
) -> Array[Dictionary]:
	if score <= 0:
		return []

	var target := maxi(target_score, 1)
	var segments: Array[Dictionary] = []
	var lower := 0
	var upper := target
	var index := 0
	while lower < score and segments.size() < MAX_THRESHOLD_SEGMENTS:
		segments.append(_threshold_segment(index, lower, upper, score))
		lower = upper
		upper = _next_threshold(upper, target, threshold_ratio)
		index += 1
	return segments


## 주어진 점수가 지금 어느 구간에 있는지 하나만 돌려준다.
static func find_threshold_segment(
	score: int,
	target_score: int,
	threshold_ratio: float = DEFAULT_THRESHOLD_RATIO
) -> Dictionary:
	var target := maxi(target_score, 1)
	var clamped_score := maxi(score, 0)
	var lower := 0
	var upper := target
	var index := 0
	while index < MAX_THRESHOLD_SEGMENTS:
		if clamped_score <= upper or index == MAX_THRESHOLD_SEGMENTS - 1:
			return _threshold_segment(index, lower, upper, clamped_score)
		lower = upper
		upper = _next_threshold(upper, target, threshold_ratio)
		index += 1
	return {}


## index번째 임계를 넘길 때 추가로 받는 골드. calculate_reward의 누적합과 같은 규칙.
static func threshold_step_reward(segment_index: int) -> int:
	return segment_index + 1


static func _threshold_segment(index: int, lower: int, upper: int, score: int) -> Dictionary:
	var segment_max := maxi(upper - lower, 1)
	return {
		"index": index,
		"lower": lower,
		"upper": upper,
		"max_value": segment_max,
		"value": clampi(score - lower, 0, segment_max),
	}


static func _next_threshold(upper: int, target: int, threshold_ratio: float) -> int:
	var next_upper := int(round(float(upper) * threshold_ratio))
	if next_upper <= upper:
		next_upper = upper + target
	return next_upper
