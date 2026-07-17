class_name ChangeToMissingProperty
extends "res://scripts/core/face_properties/face_property.gd"


func get_resolve_priority() -> int:
	return 100


func resolve_number_value(_face: Resource, context: Dictionary, _current_value: int) -> int:
	var present: Dictionary = {}
	var context_values: Array = context.get("values", [])

	for value in context_values:
		present[int(value)] = true

	for number in range(1, 7):
		if not present.has(number):
			return number

	return 1


func get_display_text(_face: Resource, _context: Dictionary, _current_text: String) -> String:
	return "V"


func has_visual_effect() -> bool:
	return true


func play_visual_effect(dice_view: Control, _face: Resource, _context: Dictionary) -> void:
	if dice_view == null:
		return

	dice_view.pivot_offset = dice_view.size * 0.5

	var tween := dice_view.create_tween()
	tween.bind_node(dice_view)
	tween.tween_property(dice_view, "scale", dice_view.scale * 1.12, 0.12)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(dice_view, "scale", Vector2.ONE, 0.12)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	dice_view.scale = Vector2.ONE
