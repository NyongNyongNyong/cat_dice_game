class_name FaceProperty
extends Resource


func get_resolve_priority() -> int:
	return 0


func resolve_number_value(_face: Resource, _context: Dictionary, current_value: int) -> int:
	return current_value


func get_display_text(_face: Resource, _context: Dictionary, current_text: String) -> String:
	return current_text


func has_visual_effect() -> bool:
	return false


func play_visual_effect(_dice_view: Control, _face: Resource, _context: Dictionary) -> void:
	pass


func apply_roll_effect(_face: Resource, _context: Dictionary) -> void:
	pass
