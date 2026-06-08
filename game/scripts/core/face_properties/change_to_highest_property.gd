class_name ChangeToHighestProperty
extends "res://scripts/core/face_properties/face_property.gd"


func resolve_number_value(face: Resource, context: Dictionary, current_value: int) -> int:
	var highest := current_value
	for candidate in context.get("faces", []):
		if candidate == face or candidate == null:
			continue
		if not candidate.has_method("is_number") or not candidate.is_number():
			continue
		highest = maxi(highest, candidate.get_base_number_value())

	return maxi(highest, 1)


func get_display_text(_face: Resource, _context: Dictionary, _current_text: String) -> String:
	return "H"


func has_visual_effect() -> bool:
	return true


func play_visual_effect(dice_view: Control, _face: Resource, context: Dictionary) -> void:
	if dice_view == null:
		return

	var resolved_value: int = context.get("resolved_value", 1)
	dice_view.pivot_offset = dice_view.size * 0.5

	var tween := dice_view.create_tween()
	tween.bind_node(dice_view)
	tween.tween_property(dice_view, "rotation_degrees", dice_view.rotation_degrees + 360.0, 0.42)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished

	if dice_view.has_method("set_value"):
		dice_view.set_value(resolved_value)
	dice_view.rotation_degrees = 0.0
