class_name DiceRoster
extends RefCounted

const BASIC_D6 := preload("res://resources/dice/basic_d6.tres")
const CHANGE_TO_HIGHEST_DIE := preload("res://resources/dice/change_to_highest_test.tres")
const STARTING_DICE_COUNT := 4

var _owned: Array[Resource] = []


func reset_to_starting() -> void:
	_owned.clear()
	for _i in STARTING_DICE_COUNT:
		_owned.append(BASIC_D6)


func get_owned_dice() -> Array[Resource]:
	return _owned.duplicate()


func get_count() -> int:
	return _owned.size()


func get_dice_resource(index: int) -> Resource:
	if index < 0 or index >= _owned.size():
		return null
	return _owned[index]


func replace_at(index: int, replacement: Resource) -> bool:
	if index < 0 or index >= _owned.size() or replacement == null:
		return false
	_owned[index] = replacement
	return true


func replace_with_h_at(index: int) -> bool:
	return replace_at(index, CHANGE_TO_HIGHEST_DIE)


func get_h_replacement_resource() -> Resource:
	return CHANGE_TO_HIGHEST_DIE
