class_name HandCalculator

const PAIR_TIERS: Array[Dictionary] = [
	{"id": "pair", "display_ko": "페어", "divisor": 1, "value": 1},
	{"id": "two_pair", "display_ko": "투페어", "divisor": 2, "value": 2},
	{"id": "three_pair", "display_ko": "쓰리페어", "divisor": 3, "value": 4},
	{"id": "four_pair", "display_ko": "포페어", "divisor": 4, "value": 7},
	{"id": "five_pair", "display_ko": "파이브페어", "divisor": 5, "value": 11},
]

const TRIPLE_TIERS: Array[Dictionary] = [
	{"id": "triple", "display_ko": "트리플", "divisor": 1, "value": 3},
	{"id": "two_triple", "display_ko": "투트리플", "divisor": 2, "value": 10},
	{"id": "three_triple", "display_ko": "쓰리트리플", "divisor": 3, "value": 22},
]

const QUAD_TIERS: Array[Dictionary] = [
	{"id": "quad", "display_ko": "쿼드", "divisor": 1, "value": 8},
	{"id": "two_quad", "display_ko": "투쿼드", "divisor": 2, "value": 28},
]

const PENTA_TIERS: Array[Dictionary] = [
	{"id": "penta", "display_ko": "펜타", "divisor": 1, "value": 16},
	{"id": "two_penta", "display_ko": "투펜타", "divisor": 2, "value": 60},
]

const HIGH_KIND_HANDS: Array[Dictionary] = [
	{"id": "hexa", "display_ko": "헥사", "size": 6, "value": 28},
	{"id": "hepta", "display_ko": "헵타", "size": 7, "value": 45},
	{"id": "octa", "display_ko": "옥타", "size": 8, "value": 70},
	{"id": "nona", "display_ko": "논나", "size": 9, "value": 100},
	{"id": "deca", "display_ko": "데카", "size": 10, "value": 140},
]

const STRAIGHT_BY_LENGTH: Dictionary = {
	5: {"id": "straight_5", "display_ko": "5 스트레이트", "value": 8},
	6: {"id": "straight_6", "display_ko": "6 스트레이트", "value": 16},
	7: {"id": "straight_7", "display_ko": "7 스트레이트", "value": 28},
	8: {"id": "straight_8", "display_ko": "8 스트레이트", "value": 44},
	9: {"id": "straight_9", "display_ko": "9 스트레이트", "value": 64},
	10: {"id": "straight_10", "display_ko": "10 스트레이트", "value": 90},
}

const STAIR_FAMILIES: Array[Dictionary] = [
	{
		"chunk": 2,
		"min_length": 2,
		"max_length": 5,
		"tiers": {
			2: {"id": "pair_stair_2", "display_ko": "2 페어 계단", "value": 5},
			3: {"id": "pair_stair_3", "display_ko": "3 페어 계단", "value": 10},
			4: {"id": "pair_stair_4", "display_ko": "4 페어 계단", "value": 18},
			5: {"id": "pair_stair_5", "display_ko": "5 페어 계단", "value": 30},
		},
	},
	{
		"chunk": 3,
		"min_length": 2,
		"max_length": 3,
		"tiers": {
			2: {"id": "triple_stair_2", "display_ko": "2 트리플 계단", "value": 24},
			3: {"id": "triple_stair_3", "display_ko": "3 트리플 계단", "value": 50},
		},
	},
	{
		"chunk": 4,
		"min_length": 2,
		"max_length": 2,
		"tiers": {2: {"id": "quad_stair_2", "display_ko": "2 쿼드 계단", "value": 70}},
	},
	{
		"chunk": 5,
		"min_length": 2,
		"max_length": 2,
		"tiers": {2: {"id": "penta_stair_2", "display_ko": "2 펜타 계단", "value": 120}},
	},
]

const FULL_HOUSE_VALUE := 8


static func evaluate(dice_values: Array[int]) -> HandEvaluation:
	var result := HandEvaluation.new()
	result.dice_values = dice_values.duplicate()
	result.number_sum = ScoreCalculator.sum_numbers(dice_values)
	result.steps = _pick_highest_step(_build_steps(dice_values))
	result.hand_value_sum = _sum_step_points(result.steps)
	if result.hand_value_sum <= 0:
		result.hand_value_sum = 1
	result.total_score = result.number_sum * result.hand_value_sum
	return result


static func summarize_steps(steps: Array[HandStep]) -> Array[Dictionary]:
	var order: Array[String] = []
	var counts: Dictionary = {}
	var display_names: Dictionary = {}

	for step in steps:
		if not counts.has(step.hand_id):
			order.append(step.hand_id)
			display_names[step.hand_id] = step.display_ko
			counts[step.hand_id] = 0
		counts[step.hand_id] = int(counts[step.hand_id]) + 1

	var summaries: Array[Dictionary] = []
	for hand_id in order:
		summaries.append({
			"hand_id": hand_id,
			"display_ko": display_names[hand_id],
			"count": counts[hand_id],
		})
	return summaries


static func _sum_step_points(steps: Array[HandStep]) -> int:
	var total := 0
	for step in steps:
		total += step.points_added
	return total


static func _pick_highest_step(steps: Array[HandStep]) -> Array[HandStep]:
	if steps.is_empty():
		return []

	var best: HandStep = steps[0]
	for step in steps:
		if step.points_added > best.points_added:
			best = step
	return [best]


static func _build_steps(dice_values: Array[int]) -> Array[HandStep]:
	var steps: Array[HandStep] = []

	_append_bundle_series_steps(steps, dice_values, 2, PAIR_TIERS)
	_append_bundle_series_steps(steps, dice_values, 3, TRIPLE_TIERS)
	_append_bundle_series_steps(steps, dice_values, 4, QUAD_TIERS)
	_append_bundle_series_steps(steps, dice_values, 5, PENTA_TIERS)

	for hand_def in HIGH_KIND_HANDS:
		_append_high_kind_steps(steps, dice_values, hand_def)

	_append_longest_straight_steps(steps, dice_values)
	_append_full_house_steps(steps, dice_values)

	for family in STAIR_FAMILIES:
		_append_longest_stair_steps(steps, dice_values, family)

	return steps


static func _append_bundle_series_steps(
	steps: Array[HandStep],
	dice_values: Array[int],
	chunk_size: int,
	tiers: Array[Dictionary],
) -> void:
	var chunks := _collect_n_kind_chunks(dice_values, chunk_size)
	if chunks.is_empty():
		return

	for tier_def in tiers:
		var tier_count: int = int(chunks.size() / tier_def["divisor"])
		if tier_count <= 0:
			continue

		var divisor: int = tier_def["divisor"]
		var value: int = tier_def["value"]

		for instance in tier_count:
			var start_chunk := instance * divisor
			var end_chunk := mini((instance + 1) * divisor, chunks.size())
			var highlight: Array[int] = []
			for chunk_index in range(start_chunk, end_chunk):
				highlight.append_array(chunks[chunk_index])

			steps.append(HandStep.new(
				tier_def["id"],
				tier_def["display_ko"],
				highlight,
				value,
			))


static func _append_high_kind_steps(
	steps: Array[HandStep],
	dice_values: Array[int],
	hand_def: Dictionary,
) -> void:
	var size: int = hand_def["size"]
	var value: int = hand_def["value"]
	for face in range(1, 7):
		var pool := _indices_for_face(dice_values, face).duplicate()
		while pool.size() >= size:
			var chunk: Array[int] = pool.slice(0, size)
			pool = pool.slice(size)
			steps.append(HandStep.new(
				hand_def["id"],
				hand_def["display_ko"],
				chunk,
				value,
			))


static func _append_longest_straight_steps(steps: Array[HandStep], dice_values: Array[int]) -> void:
	var length := _find_longest_straight_length(dice_values)
	if length < 5:
		return

	var hand_def: Dictionary = STRAIGHT_BY_LENGTH[length]
	var formations := _collect_straight_formations(dice_values, length)
	for formation in formations:
		steps.append(HandStep.new(
			hand_def["id"],
			hand_def["display_ko"],
			formation,
			hand_def["value"],
		))


static func _find_longest_straight_length(dice_values: Array[int]) -> int:
	for length in range(10, 4, -1):
		if not _collect_straight_formations(dice_values, length).is_empty():
			return length
	return 0


static func _append_full_house_steps(steps: Array[HandStep], dice_values: Array[int]) -> void:
	# hand-scoring-v2.md §9 — Full House 전용 pool, Triple/Pair 계열 chunk와 분리
	var pools := _build_face_pools(dice_values)
	while true:
		var choice := _pick_best_full_house(pools)
		if choice.is_empty():
			break

		var triple_face: int = choice["triple_face"]
		var pair_face: int = choice["pair_face"]
		var triple: Array[int] = pools[triple_face].slice(0, 3)
		pools[triple_face] = pools[triple_face].slice(3)
		var pair: Array[int] = pools[pair_face].slice(0, 2)
		pools[pair_face] = pools[pair_face].slice(2)

		var highlight: Array[int] = triple.duplicate()
		highlight.append_array(pair)
		steps.append(HandStep.new(
			"full_house",
			"풀하우스",
			highlight,
			FULL_HOUSE_VALUE,
		))


static func _pick_best_full_house(pools: Dictionary) -> Dictionary:
	var best_score := 0
	var best_triple_face := -1
	var best_pair_face := -1

	for triple_face in range(1, 7):
		if pools[triple_face].size() < 3:
			continue
		for pair_face in range(1, 7):
			if pair_face == triple_face or pools[pair_face].size() < 2:
				continue
			var next_pools := _pools_after_full_house(pools, triple_face, pair_face)
			var score := 1 + _count_full_houses_in_pools(next_pools)
			if score > best_score:
				best_score = score
				best_triple_face = triple_face
				best_pair_face = pair_face

	if best_triple_face < 0:
		return {}

	return {"triple_face": best_triple_face, "pair_face": best_pair_face}


static func _count_full_houses_in_pools(pools: Dictionary) -> int:
	var best := 0
	for triple_face in range(1, 7):
		if pools[triple_face].size() < 3:
			continue
		for pair_face in range(1, 7):
			if pair_face == triple_face or pools[pair_face].size() < 2:
				continue
			var next_pools := _pools_after_full_house(pools, triple_face, pair_face)
			best = maxi(best, 1 + _count_full_houses_in_pools(next_pools))
	return best


static func _pools_after_full_house(
	pools: Dictionary,
	triple_face: int,
	pair_face: int,
) -> Dictionary:
	var next: Dictionary = {}
	for face in range(1, 7):
		next[face] = pools[face].duplicate()
	next[triple_face] = next[triple_face].slice(3)
	next[pair_face] = next[pair_face].slice(2)
	return next


static func _build_face_pools(dice_values: Array[int]) -> Dictionary:
	var pools: Dictionary = {}
	for face in range(1, 7):
		pools[face] = _indices_for_face(dice_values, face).duplicate()
	return pools


static func _append_longest_stair_steps(
	steps: Array[HandStep],
	dice_values: Array[int],
	family: Dictionary,
) -> void:
	var chunk_size: int = family["chunk"]
	var min_length: int = family["min_length"]
	var max_length: int = family["max_length"]
	var tiers: Dictionary = family["tiers"]

	var length := _find_longest_stair_length(dice_values, chunk_size, min_length, max_length)
	if length <= 0:
		return

	var hand_def: Dictionary = tiers[length]
	var buckets := _build_chunk_buckets(dice_values, chunk_size)
	var formations := _collect_stair_formations(buckets, length)
	for formation in formations:
		steps.append(HandStep.new(
			hand_def["id"],
			hand_def["display_ko"],
			formation,
			hand_def["value"],
		))


static func _find_longest_stair_length(
	dice_values: Array[int],
	chunk_size: int,
	min_length: int,
	max_length: int,
) -> int:
	for length in range(max_length, min_length - 1, -1):
		var buckets := _build_chunk_buckets(dice_values, chunk_size)
		if not _collect_stair_formations(buckets, length).is_empty():
			return length
	return 0


static func _collect_stair_formations(buckets: Dictionary, stair_length: int) -> Array:
	var formations: Array = []
	while true:
		var found := false
		for start_face in range(1, 7 - stair_length + 1):
			if not _can_take_stair(buckets, start_face, stair_length):
				continue

			var formation: Array[int] = []
			for face in range(start_face, start_face + stair_length):
				var chunk: Array = buckets[face].pop_front()
				formation.append_array(chunk)
			formations.append(formation)
			found = true
			break

		if not found:
			break
	return formations


static func _indices_for_face(dice_values: Array[int], face: int) -> Array[int]:
	var indices: Array[int] = []
	for i in dice_values.size():
		if dice_values[i] == face:
			indices.append(i)
	return indices


static func _indices_by_face(dice_values: Array[int]) -> Dictionary:
	var buckets: Dictionary = {}
	for i in dice_values.size():
		var face: int = dice_values[i]
		if not buckets.has(face):
			buckets[face] = []
		buckets[face].append(i)
	return buckets


static func _collect_n_kind_chunks(dice_values: Array[int], chunk_size: int) -> Array:
	var chunks: Array = []
	for face in range(1, 7):
		var pool := _indices_for_face(dice_values, face).duplicate()
		while pool.size() >= chunk_size:
			chunks.append(pool.slice(0, chunk_size))
			pool = pool.slice(chunk_size)
	return chunks


static func _collect_straight_formations(dice_values: Array[int], length: int) -> Array:
	var buckets := _indices_by_face(dice_values)
	for face in range(1, 7):
		if not buckets.has(face):
			buckets[face] = []

	var formations: Array = []
	while true:
		var found := false
		for start_face in range(1, 7 - length + 1):
			if not _can_take_straight(buckets, start_face, length):
				continue

			var formation: Array[int] = []
			for face in range(start_face, start_face + length):
				formation.append(buckets[face].pop_front())
			formations.append(formation)
			found = true
			break

		if not found:
			break

	return formations


static func _can_take_straight(buckets: Dictionary, start_face: int, length: int) -> bool:
	for face in range(start_face, start_face + length):
		if not buckets.has(face) or buckets[face].is_empty():
			return false
	return true


static func _build_chunk_buckets(dice_values: Array[int], chunk_size: int) -> Dictionary:
	var buckets: Dictionary = {}
	for face in range(1, 7):
		buckets[face] = []
		var pool := _indices_for_face(dice_values, face).duplicate()
		while pool.size() >= chunk_size:
			buckets[face].append(pool.slice(0, chunk_size))
			pool = pool.slice(chunk_size)
	return buckets


static func _can_take_stair(buckets: Dictionary, start_face: int, stair_length: int) -> bool:
	for face in range(start_face, start_face + stair_length):
		if not buckets.has(face) or buckets[face].is_empty():
			return false
	return true
