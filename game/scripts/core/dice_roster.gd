class_name DiceRoster
extends RefCounted

const CatalogService := preload("res://scripts/core/dice_catalog_service.gd")

var _owned: Array[Resource] = []


func reset_to_starting() -> void:
	_owned.clear()
	var catalog = CatalogService.shared()
	for dice_id in catalog.get_starter_owned_ids():
		var die: Resource = _copy_catalog_dice(dice_id)
		if die == null:
			push_error("DiceRoster: unknown starter dice_id '%s'" % dice_id)
			continue
		_owned.append(die)


func get_owned_dice() -> Array[Resource]:
	return _owned.duplicate()


func get_count() -> int:
	return _owned.size()


func get_dice_resource(index: int) -> Resource:
	if index < 0 or index >= _owned.size():
		return null
	return _owned[index]


func add_dice(dice_id: String) -> bool:
	var die: Resource = _copy_catalog_dice(dice_id)
	if die == null:
		return false
	_owned.append(die)
	return true


func replace_at(index: int, replacement: Resource) -> bool:
	if index < 0 or index >= _owned.size() or replacement == null:
		return false
	_owned[index] = replacement
	return true


func replace_at_index(index: int, dice_id: String) -> bool:
	var replacement: Resource = _copy_catalog_dice(dice_id)
	if replacement == null:
		return false
	return replace_at(index, replacement)


func swap_indices(first_index: int, second_index: int) -> bool:
	if first_index < 0 or first_index >= _owned.size():
		return false
	if second_index < 0 or second_index >= _owned.size():
		return false
	if first_index == second_index:
		return true

	var first_die := _owned[first_index]
	_owned[first_index] = _owned[second_index]
	_owned[second_index] = first_die
	return true


func _copy_catalog_dice(dice_id: String) -> Resource:
	var template: Resource = CatalogService.shared().get_dice(dice_id)
	if template == null:
		return null
	return template.duplicate(true)
