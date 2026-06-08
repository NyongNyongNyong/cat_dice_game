class_name NumberFace
extends "res://scripts/core/dice_face.gd"

@export var value: int = 1


func is_number() -> bool:
	return true


func get_base_number_value() -> int:
	return value


func get_display_text(_context: Dictionary = {}) -> String:
	# 숫자 면은 dice.gd pip 레이아웃으로만 표시. display_name·resolved 값 텍스트 금지.
	return ""
