class_name DiceFace
extends Resource

@export var display_name: String = ""
@export var properties: Array[Resource] = []


func is_number() -> bool:
	return false


func get_base_number_value() -> int:
	return 0


func resolve_number_value(context: Dictionary = {}) -> int:
	var value := get_base_number_value()
	for property in properties:
		if property != null and property.has_method("resolve_number_value"):
			value = property.resolve_number_value(self, context, value)
	return value


func get_display_text(context: Dictionary = {}) -> String:
	var text := display_name
	for property in properties:
		if property != null and property.has_method("get_display_text"):
			text = property.get_display_text(self, context, text)
	return text


func has_visual_effect() -> bool:
	for property in properties:
		if property != null and property.has_method("has_visual_effect") and property.has_visual_effect():
			return true
	return false


func play_visual_effect(dice_view: Control, context: Dictionary = {}) -> void:
	for property in properties:
		if property != null and property.has_method("play_visual_effect"):
			await property.play_visual_effect(dice_view, self, context)
