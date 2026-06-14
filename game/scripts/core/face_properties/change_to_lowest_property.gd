class_name ChangeToLowestProperty
extends "res://scripts/core/face_properties/face_property.gd"


func get_resolve_priority() -> int:
	return 100


func resolve_number_value(face: Resource, context: Dictionary, current_value: int) -> int:
	var lowest := 7
	var found := false
	var context_faces: Array = context.get("faces", [])
	var context_values: Array = context.get("values", [])
	var dice_index: int = int(context.get("dice_index", -1))

	for i in context_faces.size():
		if i == dice_index:
			continue
		var candidate = context_faces[i]
		if candidate == face or candidate == null:
			continue
		if not candidate.has_method("is_number") or not candidate.is_number():
			continue
		found = true
		if i < context_values.size():
			lowest = mini(lowest, int(context_values[i]))
		else:
			lowest = mini(lowest, candidate.get_base_number_value())

	if not found:
		return maxi(current_value, 1)
	return maxi(lowest, 1)


func get_display_text(_face: Resource, _context: Dictionary, _current_text: String) -> String:
	return "L"


func has_visual_effect() -> bool:
	return true


func play_visual_effect(dice_view: Control, _face: Resource, _context: Dictionary) -> void:
	if dice_view == null:
		return

	dice_view.pivot_offset = dice_view.size * 0.5

	var tween := dice_view.create_tween()
	tween.bind_node(dice_view)
	tween.tween_property(dice_view, "rotation_degrees", dice_view.rotation_degrees - 360.0, 0.42)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished
	dice_view.rotation_degrees = 0.0
