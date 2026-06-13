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
	var resolved_context_faces := context_faces.duplicate()
	var face_index := resolved_context_faces.find(face)
	if resolved_context_faces.is_empty() or face_index < 0:
		resolved_context_faces.append(face)
		face_index = resolved_context_faces.size() - 1

	var values := resolve_face_values(resolved_context_faces)
	return int(values[face_index])


func resolve_face_values(context_faces: Array[Resource]) -> Array[int]:
	var values: Array[int] = []
	for face in context_faces:
		values.append(_get_base_resolved_value(face))

	var property_entries := _get_sorted_property_entries(context_faces)
	for entry in property_entries:
		var dice_index: int = entry["dice_index"]
		if dice_index < 0 or dice_index >= values.size():
			continue
		var property: Resource = entry["property"]
		var face: Resource = context_faces[dice_index]
		values[dice_index] = property.resolve_number_value(
			face,
			{
				"faces": context_faces,
				"values": values,
				"dice_index": dice_index,
				"resolve_priority": entry["priority"],
			},
			int(values[dice_index])
		)
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


func _get_base_resolved_value(face: Resource) -> int:
	if face == null:
		return 1
	if face.has_method("get_base_number_value"):
		return maxi(face.get_base_number_value(), 1)
	return 1


func _get_sorted_property_entries(context_faces: Array[Resource]) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for dice_index in context_faces.size():
		var face: Resource = context_faces[dice_index]
		if face == null:
			continue
		var properties_value = face.get("properties")
		if typeof(properties_value) != TYPE_ARRAY:
			continue
		var properties: Array = properties_value
		for property_index in properties.size():
			var property: Resource = properties[property_index]
			if property == null or not property.has_method("resolve_number_value"):
				continue
			entries.append(
				{
					"dice_index": dice_index,
					"property_index": property_index,
					"property": property,
					"priority": _get_property_resolve_priority(property),
				}
			)

	entries.sort_custom(_compare_property_entries)
	return entries


func _get_property_resolve_priority(property: Resource) -> int:
	if property.has_method("get_resolve_priority"):
		return property.get_resolve_priority()
	return 0


func _compare_property_entries(a: Dictionary, b: Dictionary) -> bool:
	var a_priority: int = a["priority"]
	var b_priority: int = b["priority"]
	if a_priority != b_priority:
		return a_priority < b_priority

	var a_dice_index: int = a["dice_index"]
	var b_dice_index: int = b["dice_index"]
	if a_dice_index != b_dice_index:
		return a_dice_index < b_dice_index

	return int(a["property_index"]) < int(b["property_index"])
