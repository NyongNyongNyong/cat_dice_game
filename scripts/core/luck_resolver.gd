class_name LuckResolver

## 행운 기반 결과 선택 (GDD §4.3).
## 배치된 주사위 중 일부를 랜덤 확정하고, 남은 ENUM_DICE(≤4)개는 6^k 전수 계산해
## 가능한 최종 점수 분포를 만든 뒤, 행운 수치에 따라 분포의 하위/상위를 잘라내고
## 남은 결과 중 하나를 무작위로 선택한다. 주사위 눈 자체는 조작하지 않는다.

const HandCalculator := preload("res://scripts/core/hand_calculator.gd")

## 전수 계산 대상 주사위 최대 수. 남은 주사위는 6^ENUM_DICE 조합으로 enumerate.
const ENUM_DICE: int = 4
## 컷 비율 점근 상한(<1.0): 행운이 아무리 높아도 100% 안전은 불가.
const CUT_FRACTION_MAX: float = 0.9
## 로그 스케일 계수: 클수록 같은 행운에서 더 많이 깎임.
## v2 튜닝(2026-07): L=30 → f≈0.5, L=10 → f≈0.27 (구 K=0.15는 초반 과급)
const CUT_FRACTION_K: float = 5.0 / 120.0


## dice_resources: Array[Resource], luck: float, value_resolver: Callable(Array)->Array[int]
## 반환: Array[Resource] — 각 주사위에 확정된 면 (입력 순서).
static func resolve(
	dice_resources: Array,
	luck: float,
	value_resolver: Callable,
	rng: RandomNumberGenerator,
) -> Array[Resource]:
	var n := dice_resources.size()
	var result: Array[Resource] = []
	result.resize(n)
	if n == 0:
		return result

	# 전수 대상 인덱스를 무작위로 고른다 (나머지는 즉시 랜덤 확정).
	var order: Array[int] = []
	for i in n:
		order.append(i)
	_shuffle(order, rng)
	var enum_count := mini(n, ENUM_DICE)
	var enum_indices: Array[int] = order.slice(0, enum_count)
	enum_indices.sort()

	# 비전수 주사위는 지금 랜덤 확정.
	var is_enum := {}
	for idx in enum_indices:
		is_enum[idx] = true
	for i in n:
		if not is_enum.has(i):
			result[i] = _random_face(dice_resources[i], rng)

	# 전수 대상 각 주사위의 후보 면.
	var enum_face_lists: Array = []
	for idx in enum_indices:
		enum_face_lists.append(_faces_of(dice_resources[idx]))

	var combos := _cartesian(enum_face_lists)
	if combos.is_empty():
		return result

	# 각 조합의 최종 점수 계산.
	var outcomes: Array = []
	for combo in combos:
		var full: Array[Resource] = result.duplicate()
		for j in enum_indices.size():
			full[enum_indices[j]] = combo[j]
		var values = value_resolver.call(full)
		var score: int = HandCalculator.evaluate(values).total_score
		outcomes.append({"combo": combo, "score": score})

	outcomes.sort_custom(func(a, b): return a["score"] < b["score"])

	# 행운 컷.
	var cut_count := int(floor(_cut_fraction(luck) * float(outcomes.size())))
	cut_count = clampi(cut_count, 0, outcomes.size() - 1)
	var pool: Array
	if luck >= 0.0:
		pool = outcomes.slice(cut_count, outcomes.size())  # 하위 제거
	else:
		pool = outcomes.slice(0, outcomes.size() - cut_count)  # 상위 제거
	if pool.is_empty():
		pool = outcomes

	var chosen: Dictionary = pool[rng.randi_range(0, pool.size() - 1)]
	var chosen_combo: Array = chosen["combo"]
	for j in enum_indices.size():
		result[enum_indices[j]] = chosen_combo[j]
	return result


static func cut_fraction(luck: float) -> float:
	return _cut_fraction(luck)


static func _cut_fraction(luck: float) -> float:
	return CUT_FRACTION_MAX * (1.0 - 1.0 / (1.0 + CUT_FRACTION_K * absf(luck)))


static func _random_face(resource: Resource, rng: RandomNumberGenerator) -> Resource:
	var faces := _faces_of(resource)
	if faces.is_empty():
		return null
	return faces[rng.randi_range(0, faces.size() - 1)]


static func _faces_of(resource: Resource) -> Array:
	if resource != null and resource.has_method("get_faces"):
		return resource.get_faces()
	return []


static func _shuffle(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp


static func _cartesian(lists: Array) -> Array:
	var result: Array = [[]]
	for list in lists:
		var next: Array = []
		for prefix in result:
			for item in list:
				var combo: Array = prefix.duplicate()
				combo.append(item)
				next.append(combo)
		result = next
	return result
