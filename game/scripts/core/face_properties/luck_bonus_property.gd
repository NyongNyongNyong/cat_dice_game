class_name LuckBonusProperty
extends "res://scripts/core/face_properties/face_property.gd"

@export var amount: float = 1.0


func resolve_number_value(_face: Resource, _context: Dictionary, _current_value: int) -> int:
	return 0


func apply_roll_effect(_face: Resource, context: Dictionary) -> void:
	var run_manager = context.get("run_manager")
	if run_manager != null and run_manager.has_method("add_luck"):
		run_manager.add_luck(amount)


func get_display_text(_face: Resource, _context: Dictionary, _current_text: String) -> String:
	if is_equal_approx(amount, 1.0):
		return "☘"
	if amount == floor(amount):
		return "☘%d" % int(amount)
	return "☘%s" % str(amount)
