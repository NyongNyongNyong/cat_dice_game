class_name DiceResource
extends Resource

const NumberFaceScript := preload("res://scripts/core/number_face.gd")

@export var id: StringName = &"dice_basic"
@export var display_name: String = "Basic Die"
@export var faces: Array[Resource] = []
var face_values: Array[int] = [1, 2, 3, 4, 5, 6]


func get_face_count() -> int:
	return get_faces().size()


func get_face_values() -> Array[int]:
	return resolve_face_values(get_faces())


func get_faces() -> Array[Resource]:
	var resolved_faces: Array[Resource] = []
	for face in faces:
		if face != null:
			resolved_faces.append(face)
	if not resolved_faces.is_empty():
		return resolved_faces

	for value in _fallback_face_values():
		var face: Resource = NumberFaceScript.new()
		face.value = value
		resolved_faces.append(face)
	return resolved_faces


func roll_face() -> Resource:
	var resolved_faces := get_faces()
	return resolved_faces[randi_range(0, resolved_faces.size() - 1)]


func roll_value() -> int:
	return resolve_face_value(roll_face())


func resolve_face_value(face: Resource, context_faces: Array[Resource] = []) -> int:
	if face == null:
		return 1
	var resolved_context_faces := context_faces
	if resolved_context_faces.is_empty():
		resolved_context_faces = [face]
	if face.has_method("resolve_number_value"):
		return face.resolve_number_value({"faces": resolved_context_faces})
	return 1


func resolve_face_values(context_faces: Array[Resource]) -> Array[int]:
	var values: Array[int] = []
	for face in context_faces:
		values.append(resolve_face_value(face, context_faces))
	return values


func get_roster_preview_face() -> Resource:
	var all_faces := get_faces()
	if all_faces.is_empty():
		return null

	var best_number: Resource = null
	var best_value := -1
	var first_special: Resource = null

	for face in all_faces:
		if face == null:
			continue
		if face.has_method("is_number") and face.is_number():
			var pip_value: int = face.get_base_number_value()
			if pip_value > best_value:
				best_value = pip_value
				best_number = face
		elif first_special == null:
			first_special = face

	if first_special != null:
		return first_special
	if best_number != null:
		return best_number
	return all_faces[0]


func get_roster_preview_value(context_faces: Array[Resource] = []) -> int:
	var preview_face := get_roster_preview_face()
	if preview_face == null:
		return 1

	var ctx := context_faces
	if ctx.is_empty():
		ctx = get_faces()
	return resolve_face_value(preview_face, ctx)


func _fallback_face_values() -> Array[int]:
	if face_values.is_empty():
		return [1]
	return face_values.duplicate()
