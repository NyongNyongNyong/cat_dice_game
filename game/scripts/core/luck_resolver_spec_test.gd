extends SceneTree

const LuckResolver := preload("res://scripts/core/luck_resolver.gd")
const HandCalculator := preload("res://scripts/core/hand_calculator.gd")
const DiceResourceScript := preload("res://scripts/core/dice_resource.gd")
const NumberFaceScript := preload("res://scripts/core/number_face.gd")

var _failed := 0


func _init() -> void:
	_test_cut_fraction()
	_test_luck_bias()

	if _failed > 0:
		push_error("Luck resolver spec tests failed: %d" % _failed)
	quit(_failed)


func _test_cut_fraction() -> void:
	_expect(is_equal_approx(LuckResolver.cut_fraction(0.0), 0.0), "luck 0 -> no cut")
	_expect(LuckResolver.cut_fraction(50.0) < LuckResolver.CUT_FRACTION_MAX, "cut never reaches max")
	_expect(
		LuckResolver.cut_fraction(50.0) > LuckResolver.cut_fraction(5.0),
		"cut increases with luck"
	)
	_expect(
		is_equal_approx(LuckResolver.cut_fraction(-20.0), LuckResolver.cut_fraction(20.0)),
		"cut symmetric in magnitude"
	)


func _test_luck_bias() -> void:
	var dice: Array = [_basic_die(), _basic_die()]
	var resolver_cb := Callable(self, "_resolve_values")

	var global_min := 1 << 30
	var global_max := -1
	var faces_a: Array = dice[0].get_faces()
	var faces_b: Array = dice[1].get_faces()
	for fa in faces_a:
		for fb in faces_b:
			var score: int = HandCalculator.evaluate(_resolve_values([fa, fb])).total_score
			global_min = mini(global_min, score)
			global_max = maxi(global_max, score)

	var rng := RandomNumberGenerator.new()
	rng.seed = 987654321

	var samples := 600
	var high_min := 1 << 30
	var low_max := -1
	var neutral_hit_min := false
	var neutral_hit_max := false

	for _i in samples:
		var high: Array = LuckResolver.resolve(dice, 60.0, resolver_cb, rng)
		high_min = mini(high_min, _score_of(high))

		var low: Array = LuckResolver.resolve(dice, -60.0, resolver_cb, rng)
		low_max = maxi(low_max, _score_of(low))

		var neutral: Array = LuckResolver.resolve(dice, 0.0, resolver_cb, rng)
		var ns := _score_of(neutral)
		if ns == global_min:
			neutral_hit_min = true
		if ns == global_max:
			neutral_hit_max = true

	_expect(global_max > global_min, "outcome distribution has spread")
	_expect(high_min > global_min, "high luck never picks the worst outcome")
	_expect(low_max < global_max, "low luck never picks the best outcome")
	_expect(neutral_hit_min, "neutral luck can reach the worst outcome")
	_expect(neutral_hit_max, "neutral luck can reach the best outcome")


func _score_of(faces: Array) -> int:
	return HandCalculator.evaluate(_resolve_values(faces)).total_score


func _resolve_values(faces: Array) -> Array[int]:
	var values: Array[int] = []
	for face in faces:
		values.append(face.get_base_number_value())
	return values


func _basic_die() -> Resource:
	var die: Resource = DiceResourceScript.new()
	var faces: Array[Resource] = []
	for value in [1, 2, 3, 4, 5, 6]:
		var face: Resource = NumberFaceScript.new()
		face.value = value
		faces.append(face)
	die.faces = faces
	return die


func _expect(condition: bool, label: String) -> void:
	if condition:
		print("  OK  %s" % label)
	else:
		print("FAIL  %s" % label)
		_failed += 1
