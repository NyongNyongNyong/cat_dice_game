class_name SpecialFace
extends "res://scripts/core/dice_face.gd"

@export var symbol_id: StringName = &"special"


func get_display_text(context: Dictionary = {}) -> String:
	var text := ""
	for property in properties:
		if property != null and property.has_method("get_display_text"):
			text = property.get_display_text(self, context, text)
	if not text.is_empty():
		return text
	if symbol_id != &"":
		return str(symbol_id)
	return ""
