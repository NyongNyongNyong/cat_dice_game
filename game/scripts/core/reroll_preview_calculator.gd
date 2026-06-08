class_name RerollPreviewCalculator

const PreviewResult := preload("res://scripts/core/reroll_preview_result.gd")
const DefaultDiceResource := preload("res://resources/dice/basic_d6.tres")
const DEFAULT_FACE_VALUES: Array[int] = [1, 2, 3, 4, 5, 6]


static func compute(
	dice_values: Array[int],
	dice_index: int,
	face_values: Array[int] = DEFAULT_FACE_VALUES,
):
	var result: RefCounted = PreviewResult.new()
	if dice_values.is_empty() or dice_index < 0 or dice_index >= dice_values.size():
		return result
	if face_values.is_empty():
		return result

	result.current_score = HandCalculator.evaluate(dice_values).total_score
	result.max_score = result.current_score
	result.min_score = result.current_score

	for face_value in face_values:
		var trial_values := dice_values.duplicate()
		trial_values[dice_index] = face_value
		var score := HandCalculator.evaluate(trial_values).total_score
		result.max_score = maxi(result.max_score, score)
		result.min_score = mini(result.min_score, score)

	result.delta_up = result.max_score - result.current_score
	result.delta_down = result.min_score - result.current_score
	return result


static func compute_from_faces(
	dice_faces: Array[Resource],
	dice_index: int,
	candidate_faces: Array[Resource],
):
	var result: RefCounted = PreviewResult.new()
	if dice_faces.is_empty() or dice_index < 0 or dice_index >= dice_faces.size():
		return result
	if candidate_faces.is_empty():
		return result

	var current_values := _resolve_faces(dice_faces)
	result.current_score = HandCalculator.evaluate(current_values).total_score
	result.max_score = result.current_score
	result.min_score = result.current_score

	for candidate in candidate_faces:
		var trial_faces := dice_faces.duplicate()
		trial_faces[dice_index] = candidate
		var trial_values := _resolve_faces(trial_faces)
		var score := HandCalculator.evaluate(trial_values).total_score
		result.max_score = maxi(result.max_score, score)
		result.min_score = mini(result.min_score, score)

	result.delta_up = result.max_score - result.current_score
	result.delta_down = result.min_score - result.current_score
	return result


static func _resolve_faces(faces: Array[Resource]) -> Array[int]:
	var values: Array[int] = []
	for face in faces:
		values.append(DefaultDiceResource.resolve_face_value(face, faces))
	return values
