class_name NumberFace
extends "res://scripts/core/dice_face.gd"

@export var value: int = 1


func is_number() -> bool:
	return true


func get_base_number_value() -> int:
	return value
