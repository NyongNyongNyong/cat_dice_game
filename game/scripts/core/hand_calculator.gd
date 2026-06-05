class_name HandCalculator

const HAND_VALUE := 1

const N_KIND_HANDS: Array[Dictionary] = [
	{"id": "pair", "display_ko": "Pair", "size": 2},
	{"id": "triple", "display_ko": "Triple", "size": 3},
	{"id": "quad", "display_ko": "Quad", "size": 4},
	{"id": "penta", "display_ko": "Penta", "size": 5},
	{"id": "hexa", "display_ko": "Hexa", "size": 6},
	{"id": "hepta", "display_ko": "Hepta", "size": 7},
	{"id": "octa", "display_ko": "Octa", "size": 8},
	{"id": "nona", "display_ko": "Nona", "size": 9},
	{"id": "deca", "display_ko": "Deca", "size": 10},
]

const STRAIGHT_HANDS: Array[Dictionary] = [
	{"id": "straight_5", "display_ko": "5 Straight", "length": 5},
	{"id": "straight_6", "display_ko": "6 Straight", "length": 6},
]

const STAIR_HANDS: Array[Dictionary] = [
	{"id": "pair_stair_2", "display_ko": "2 Pair Stair", "chunk": 2, "length": 2},
	{"id": "pair_stair_3", "display_ko": "3 Pair Stair", "chunk": 2, "length": 3},
	{"id": "pair_stair_4", "display_ko": "4 Pair Stair", "chunk": 2, "length": 4},
	{"id": "pair_stair_5", "display_ko": "5 Pair Stair", "chunk": 2, "length": 5},
	{"id": "triple_stair_2", "display_ko": "2 Triple Stair", "chunk": 3, "length": 2},
	{"id": "triple_stair_3", "display_ko": "3 Triple Stair", "chunk": 3, "length": 3},
	{"id": "quad_stair_2", "display_ko": "2 Quad Stair", "chunk": 4, "length": 2},
	{"id": "penta_stair_2", "display_ko": "2 Penta Stair", "chunk": 5, "length": 2},
]


static func evaluate(dice_values: Array[int]) -> HandEvaluation:
	var result := HandEvaluation.new()
	result.dice_values = dice_values.duplicate()
	result.number_sum = ScoreCalculator.sum_numbers(dice_values)
	result.steps = _build_steps(dice_values)
	result.hand_value_sum = _sum_step_points(result.steps)
	result.total_score = result.number_sum * result.hand_value_sum
	return result


static func _sum_step_points(steps: Array[HandStep]) -> int:
	var total := 0
	for step in steps:
		total += step.points_added
	return total


static func _build_steps(dice_values: Array[int]) -> Array[HandStep]:
	var steps: Array[HandStep] = []

	for hand_def in N_KIND_HANDS:
		_append_n_kind_steps(steps, dice_values, hand_def)

	for hand_def in STRAIGHT_HANDS:
		_append_straight_steps(steps, dice_values, hand_def)

	_append_full_house_steps(steps, dice_values)

	for hand_def in STAIR_HANDS:
		_append_stair_steps(steps, dice_values, hand_def)

	return steps


static func _append_n_kind_steps(
	steps: Array[HandStep],
	dice_values: Array[int],
	hand_def: Dictionary,
) -> void:
	var size: int = hand_def["size"]
	var cumulative: Array[int] = []
	var hand_started := false

	for face in range(1, 7):
		var pool := _indices_for_face(dice_values, face).duplicate()
		while pool.size() >= size:
			var chunk := pool.slice(0, size)
			pool = pool.slice(size)
			cumulative.append_array(chunk)
			steps.append(HandStep.new(
				hand_def["id"],
				hand_def["display_ko"],
				cumulative.duplicate(),
				HAND_VALUE,
				not hand_started,
			))
			hand_started = true


static func _append_straight_steps(
	steps: Array[HandStep],
	dice_values: Array[int],
	hand_def: Dictionary,
) -> void:
	var length: int = hand_def["length"]
	var formations := _collect_straight_formations(dice_values, length)
	var hand_started := false

	for formation in formations:
		steps.append(HandStep.new(
			hand_def["id"],
			hand_def["display_ko"],
			formation,
			HAND_VALUE,
			not hand_started,
		))
		hand_started = true


static func _append_full_house_steps(steps: Array[HandStep], dice_values: Array[int]) -> void:
	var triples := _collect_n_kind_chunks(dice_values, 3)
	var pairs := _collect_n_kind_chunks(dice_values, 2)
	var hand_started := false

	while not triples.is_empty():
		var triple: Array[int] = triples[0]
		var triple_face := dice_values[triple[0]]
		var pair_index := -1

		for i in pairs.size():
			if dice_values[pairs[i][0]] != triple_face:
				pair_index = i
				break

		if pair_index < 0:
			break

		var pair: Array[int] = pairs[pair_index]
		triples.remove_at(0)
		pairs.remove_at(pair_index)

		var highlight := triple.duplicate()
		highlight.append_array(pair)
		steps.append(HandStep.new(
			"full_house",
			"Full House",
			highlight,
			HAND_VALUE,
			not hand_started,
		))
		hand_started = true


static func _append_stair_steps(
	steps: Array[HandStep],
	dice_values: Array[int],
	hand_def: Dictionary,
) -> void:
	var chunk_size: int = hand_def["chunk"]
	var stair_length: int = hand_def["length"]
	var buckets := _build_chunk_buckets(dice_values, chunk_size)
	var hand_started := false

	while true:
		var formation: Array[int] = []
		var found := false

		for start_face in range(1, 7 - stair_length + 1):
			if not _can_take_stair(buckets, start_face, stair_length):
				continue

			for face in range(start_face, start_face + stair_length):
				var chunk: Array = buckets[face].pop_front()
				formation.append_array(chunk)

			found = true
			break

		if not found:
			break

		steps.append(HandStep.new(
			hand_def["id"],
			hand_def["display_ko"],
			formation,
			HAND_VALUE,
			not hand_started,
		))
		hand_started = true


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
