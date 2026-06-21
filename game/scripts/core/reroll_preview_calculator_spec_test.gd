extends SceneTree

const PreviewCalculator := preload("res://scripts/core/reroll_preview_calculator.gd")
const HandCalculator := preload("res://scripts/core/hand_calculator.gd")
const NumberFaceScript := preload("res://scripts/core/number_face.gd")
const SpecialFaceScript := preload("res://scripts/core/special_face.gd")
const ChangeToHighestPropertyScript := preload("res://scripts/core/face_properties/change_to_highest_property.gd")

var _failed := 0


func _init() -> void:
	_expect_result_consistency([2, 3, 3, 4, 4, 5, 5, 6, 6, 6], 0)
	_expect_single_face_no_change()
	_expect_bruteforce_matches([1, 2, 3, 4, 5, 6, 1, 2, 3, 4], 0)
	_expect_bruteforce_matches([3, 3, 3, 3, 3, 3, 3, 3, 3, 3], 5)
	_expect_face_property_re_resolves_whole_board()

	if _failed > 0:
		push_error("Reroll preview spec tests failed: %d" % _failed)
	quit(_failed)


func _expect_result_consistency(values: Array[int], index: int) -> void:
	var preview = PreviewCalculator.compute(values, index)
	if preview.max_score < preview.current_score:
		_fail("max >= current", preview.current_score, preview.max_score)
	if preview.min_score > preview.current_score:
		_fail("min <= current", preview.current_score, preview.min_score)
	if preview.delta_up != preview.max_score - preview.current_score:
		_fail("delta_up", preview.max_score - preview.current_score, preview.delta_up)
	if preview.delta_down != preview.min_score - preview.current_score:
		_fail("delta_down", preview.min_score - preview.current_score, preview.delta_down)


func _expect_single_face_no_change() -> void:
	var values: Array[int] = [4, 4, 4, 4, 4, 4, 4, 4, 4, 4]
	var preview = PreviewCalculator.compute(values, 3, [4])
	if preview.delta_up != 0:
		_fail("single face delta_up", 0, preview.delta_up)
	if preview.delta_down != 0:
		_fail("single face delta_down", 0, preview.delta_down)


func _expect_bruteforce_matches(values: Array[int], index: int) -> void:
	var preview = PreviewCalculator.compute(values, index)
	var current := HandCalculator.evaluate(values).total_score
	var max_score := current
	var min_score := current
	for face in PreviewCalculator.DEFAULT_FACE_VALUES:
		var trial := values.duplicate()
		trial[index] = face
		var score := HandCalculator.evaluate(trial).total_score
		max_score = maxi(max_score, score)
		min_score = mini(min_score, score)

	if preview.delta_up != max_score - current:
		_fail("bruteforce delta_up", max_score - current, preview.delta_up)
	if preview.delta_down != min_score - current:
		_fail("bruteforce delta_down", min_score - current, preview.delta_down)


func _expect_face_property_re_resolves_whole_board() -> void:
	var five := _number_face(5)
	var highest := _highest_face()
	var dice_faces: Array[Resource] = [five, highest]
	var candidates: Array[Resource] = [_number_face(1), _number_face(6)]

	var preview = PreviewCalculator.compute_from_faces(dice_faces, 0, candidates)
	var current := HandCalculator.evaluate([5, 5]).total_score
	var best := HandCalculator.evaluate([6, 6]).total_score
	var worst := HandCalculator.evaluate([1, 1]).total_score

	if preview.current_score != current:
		_fail("face property current score", current, preview.current_score)
	if preview.delta_up != best - current:
		_fail("face property delta_up", best - current, preview.delta_up)
	if preview.delta_down != worst - current:
		_fail("face property delta_down", worst - current, preview.delta_down)


func _number_face(value: int) -> Resource:
	var face: Resource = NumberFaceScript.new()
	face.value = value
	return face


func _highest_face() -> Resource:
	var face: Resource = SpecialFaceScript.new()
	var property: Resource = ChangeToHighestPropertyScript.new()
	var properties: Array[Resource] = [property]
	face.properties = properties
	return face


func _fail(label: String, expected: int, got: int) -> void:
	_failed += 1
	push_error("%s: expected %d got %d" % [label, expected, got])
