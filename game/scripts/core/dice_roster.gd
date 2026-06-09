class_name DiceRoster
extends RefCounted

const CatalogService := preload("res://scripts/core/dice_catalog_service.gd")
const SHOP_REPLACE_OFFER_ID := "dice_triple_h"

var _owned: Array[Resource] = []


func reset_to_starting() -> void:
	_owned.clear()
	var catalog = CatalogService.shared()
	for dice_id in catalog.get_starter_owned_ids():
		var die: Resource = catalog.get_dice(dice_id)
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


func replace_at(index: int, replacement: Resource) -> bool:
	if index < 0 or index >= _owned.size() or replacement == null:
		return false
	_owned[index] = replacement
	return true


func replace_at_index(index: int, dice_id: String) -> bool:
	var replacement: Resource = CatalogService.shared().get_dice(dice_id)
	if replacement == null:
		return false
	return replace_at(index, replacement)


func get_shop_replace_offer_id() -> String:
	return SHOP_REPLACE_OFFER_ID
