class_name DiceLoadoutResource
extends Resource

@export var id: StringName = &"dice_loadout"
@export var display_name: String = "Dice Loadout"
@export var dice: Array[Resource] = []


func get_dice_count() -> int:
	return dice.size()


func get_dice_resource(dice_index: int) -> Resource:
	if dice_index < 0 or dice_index >= dice.size():
		return null
	return dice[dice_index]
