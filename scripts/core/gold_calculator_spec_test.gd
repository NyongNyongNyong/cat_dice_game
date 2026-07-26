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

	_test_threshold_segments()
	_test_threshold_step_reward_matches_total()

	if _failed > 0:
		push_error("Gold calculator spec tests failed: %d" % _failed)
	quit(_failed)


# 목표 5 · 배율 2 → 임계는 5, 10, 20, 40 …
func _test_threshold_segments() -> void:
	_expect_segment_count(0, T5, 0)
	_expect_segment_count(3, T5, 1)
	_expect_segment_count(7, T5, 2)
	_expect_segment_count(20, T5, 3)

	# 마지막(진행 중) 구간이 진행 바에 표시되는 값이다.
	_expect_last_segment(3, T5, 0, 5, 3)
	_expect_last_segment(7, T5, 1, 5, 2)
	_expect_last_segment(20, T5, 2, 10, 10)

	_expect_found_segment(0, T5, 0, 5, 0)
	_expect_found_segment(5, T5, 0, 5, 5)
	_expect_found_segment(6, T5, 1, 5, 1)


# UI가 띄우는 "+N 골드"의 누적이 calculate_reward와 어긋나면 안 된다.
func _test_threshold_step_reward_matches_total() -> void:
	var thresholds: Array[int] = [5, 10, 20, 40, 80, 160]
	var running := 0
	for index in thresholds.size():
		running += GoldCalculatorScript.threshold_step_reward(index)
		var total: int = GoldCalculatorScript.calculate_reward(thresholds[index], T5)
		if running != total:
			_fail("threshold_step_reward cumulative at %d" % thresholds[index], total, running)


func _expect_reward(final_chips: int, target_chips: int, expected: int) -> void:
	var got: int = GoldCalculatorScript.calculate_reward(final_chips, target_chips)
	if got != expected:
		_fail("S=%d T=%d" % [final_chips, target_chips], expected, got)


func _expect_segment_count(score: int, target: int, expected: int) -> void:
	var got: int = GoldCalculatorScript.build_threshold_segments(score, target).size()
	if got != expected:
		_fail("segment count S=%d T=%d" % [score, target], expected, got)


func _expect_last_segment(
	score: int,
	target: int,
	expected_index: int,
	expected_max: int,
	expected_value: int,
) -> void:
	var segments: Array[Dictionary] = GoldCalculatorScript.build_threshold_segments(score, target)
	if segments.is_empty():
		_fail("last segment S=%d T=%d (empty)" % [score, target], expected_index, -1)
		return
	_check_segment(
		"last segment S=%d T=%d" % [score, target],
		segments.back(),
		expected_index,
		expected_max,
		expected_value,
	)


func _expect_found_segment(
	score: int,
	target: int,
	expected_index: int,
	expected_max: int,
	expected_value: int,
) -> void:
	_check_segment(
		"found segment S=%d T=%d" % [score, target],
		GoldCalculatorScript.find_threshold_segment(score, target),
		expected_index,
		expected_max,
		expected_value,
	)


func _check_segment(
	label: String,
	segment: Dictionary,
	expected_index: int,
	expected_max: int,
	expected_value: int,
) -> void:
	if int(segment.get("index", -1)) != expected_index:
		_fail("%s index" % label, expected_index, int(segment.get("index", -1)))
	if int(segment.get("max_value", -1)) != expected_max:
		_fail("%s max_value" % label, expected_max, int(segment.get("max_value", -1)))
	if int(segment.get("value", -1)) != expected_value:
		_fail("%s value" % label, expected_value, int(segment.get("value", -1)))


func _fail(label: String, expected: int, got: int) -> void:
	_failed += 1
	push_error("%s: expected %d got %d" % [label, expected, got])
