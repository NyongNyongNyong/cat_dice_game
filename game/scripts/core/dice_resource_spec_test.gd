extends SceneTree

const DiceResourceScript := preload("res://scripts/core/dice_resource.gd")
const NumberFaceScript := preload("res://scripts/core/number_face.gd")
const SpecialFaceScript := preload("res://scripts/core/special_face.gd")
const ChangeToHighestPropertyScript := preload("res://scripts/core/face_properties/change_to_highest_property.gd")
const DiceLoadoutResourceScript := preload("res://scripts/core/dice_loadout_resource.gd")
const RoundControllerScript := preload("res://scripts/core/round_controller.gd")

var _failed := 0


func _init() -> void:
	_expect_resource_reports_face_values()
	_expect_resource_resolves_face_resources()
	_expect_change_to_highest_property()
	_expect_change_to_highest_display()
	_expect_controller_uses_default_resource()
	_expect_controller_uses_per_slot_resource()
	_expect_controller_uses_loadout_resource()
	_expect_controller_resolves_rolled_faces()
	_expect_controller_reports_contextual_reroll_values()
	_expect_controller_reports_contextual_reroll_preview()

	if _failed > 0:
		push_error("Dice resource spec tests failed: %d" % _failed)
	quit(_failed)


func _expect_resource_reports_face_values() -> void:
	var die: Resource = DiceResourceScript.new()
	var face_values: Array[int] = [2, 4, 8]
	die.face_values = face_values

	if die.get_face_count() != 3:
		_fail("face count", 3, die.get_face_count())
	if die.get_face_values() != [2, 4, 8]:
		_fail_array("face values", [2, 4, 8], die.get_face_values())

	face_values.clear()
	die.face_values = face_values
	if die.get_face_values() != [1]:
		_fail_array("empty face fallback", [1], die.get_face_values())


func _expect_resource_resolves_face_resources() -> void:
	var die: Resource = DiceResourceScript.new()
	var one := _number_face(1)
	var four := _number_face(4)
	var faces: Array[Resource] = [one, four]
	die.faces = faces

	if die.get_face_count() != 2:
		_fail("resource face count", 2, die.get_face_count())
	if die.get_face_values() != [1, 4]:
		_fail_array("resource face values", [1, 4], die.get_face_values())


func _expect_change_to_highest_property() -> void:
	var die: Resource = DiceResourceScript.new()
	var two := _number_face(2)
	var five := _number_face(5)
	var changer: Resource = SpecialFaceScript.new()
	changer.display_name = "Change To Highest"
	changer.symbol_id = &"change_to_highest"
	var property: Resource = ChangeToHighestPropertyScript.new()
	var properties: Array[Resource] = [property]
	changer.properties = properties

	var faces: Array[Resource] = [two, changer, five]
	if die.resolve_face_values(faces) != [2, 5, 5]:
		_fail_array("change to highest values", [2, 5, 5], die.resolve_face_values(faces))

	var only_changer: Array[Resource] = [changer]
	if die.resolve_face_values(only_changer) != [1]:
		_fail_array("change to highest fallback", [1], die.resolve_face_values(only_changer))


func _expect_change_to_highest_display() -> void:
	var changer: Resource = SpecialFaceScript.new()
	var property: Resource = ChangeToHighestPropertyScript.new()
	var properties: Array[Resource] = [property]
	changer.properties = properties

	if changer.get_display_text({"resolved_value": 6}) != "H":
		_fail_string("change to highest display", "H", changer.get_display_text({"resolved_value": 6}))
	if not changer.has_visual_effect():
		_fail_bool("change to highest has visual effect", true, changer.has_visual_effect())


func _expect_controller_uses_default_resource() -> void:
	var controller: Node = RoundControllerScript.new()
	var die: Resource = DiceResourceScript.new()
	var face_values: Array[int] = [9]
	die.face_values = face_values
	controller.default_dice_resource = die

	if controller.get_face_values(0) != [9]:
		_fail_array("controller default face values", [9], controller.get_face_values(0))
	if controller.get_dice_count() != RunManager.DICE_COUNT:
		_fail("controller default dice count", RunManager.DICE_COUNT, controller.get_dice_count())
	if controller._roll_die_value(0) != 9:
		_fail("controller default roll", 9, controller._roll_die_value(0))
	controller.free()


func _expect_controller_uses_per_slot_resource() -> void:
	var controller: Node = RoundControllerScript.new()
	var default_die: Resource = DiceResourceScript.new()
	var default_faces: Array[int] = [1]
	default_die.face_values = default_faces
	var custom_die: Resource = DiceResourceScript.new()
	var custom_faces: Array[int] = [12]
	custom_die.face_values = custom_faces
	controller.default_dice_resource = default_die
	var dice_resources: Array[Resource] = [custom_die]
	controller.dice_resources = dice_resources

	if controller.get_dice_count() != 1:
		_fail("controller array dice count", 1, controller.get_dice_count())
	if controller.get_face_values(0) != [12]:
		_fail_array("controller slot face values", [12], controller.get_face_values(0))
	if controller.get_face_values(1) != [1]:
		_fail_array("controller fallback face values", [1], controller.get_face_values(1))
	if controller._roll_die_value(0) != 12:
		_fail("controller slot roll", 12, controller._roll_die_value(0))
	if controller._roll_die_value(1) != 1:
		_fail("controller fallback roll", 1, controller._roll_die_value(1))
	controller.free()


func _expect_controller_uses_loadout_resource() -> void:
	var controller: Node = RoundControllerScript.new()
	var first_die: Resource = DiceResourceScript.new()
	first_die.face_values = _typed_ints([4])
	var second_die: Resource = DiceResourceScript.new()
	second_die.face_values = _typed_ints([6])
	var loadout: Resource = DiceLoadoutResourceScript.new()
	var dice: Array[Resource] = [first_die, second_die]
	loadout.dice = dice
	controller.dice_loadout = loadout

	if controller.get_dice_count() != 2:
		_fail("controller loadout dice count", 2, controller.get_dice_count())
	if controller.get_face_values(0) != [4]:
		_fail_array("controller loadout first die", [4], controller.get_face_values(0))
	if controller.get_face_values(1) != [6]:
		_fail_array("controller loadout second die", [6], controller.get_face_values(1))
	if controller._roll_dice_values() != [4, 6]:
		_fail_array("controller loadout roll", [4, 6], controller._roll_dice_values())
	controller.free()


func _expect_controller_resolves_rolled_faces() -> void:
	var controller: Node = RoundControllerScript.new()
	var die: Resource = DiceResourceScript.new()
	var three := _number_face(3)
	var changer: Resource = SpecialFaceScript.new()
	var property: Resource = ChangeToHighestPropertyScript.new()
	var properties: Array[Resource] = [property]
	changer.properties = properties
	var faces: Array[Resource] = [three, changer]
	die.faces = faces
	controller.default_dice_resource = die

	if controller.resolve_faces(faces) != [3, 3]:
		_fail_array("controller resolved faces", [3, 3], controller.resolve_faces(faces))
	controller.free()


func _expect_controller_reports_contextual_reroll_values() -> void:
	var controller: Node = RoundControllerScript.new()
	var die: Resource = DiceResourceScript.new()
	var two := _number_face(2)
	var changer: Resource = SpecialFaceScript.new()
	var property: Resource = ChangeToHighestPropertyScript.new()
	var properties: Array[Resource] = [property]
	changer.properties = properties
	var faces: Array[Resource] = [two, changer]
	die.faces = faces
	controller.default_dice_resource = die
	var rolled_faces: Array[Resource] = [_number_face(5), changer]
	controller.dice_faces = rolled_faces

	if controller.get_reroll_face_values(1) != [2, 5]:
		_fail_array(
			"controller contextual reroll values",
			[2, 5],
			controller.get_reroll_face_values(1)
		)
	controller.free()


func _expect_controller_reports_contextual_reroll_preview() -> void:
	var controller: Node = RoundControllerScript.new()
	var die: Resource = DiceResourceScript.new()
	var one := _number_face(1)
	var six := _number_face(6)
	var faces: Array[Resource] = [one, six]
	die.faces = faces
	controller.default_dice_resource = die
	var rolled_faces: Array[Resource] = [_number_face(5), _highest_face()]
	controller.dice_faces = rolled_faces

	var preview = controller.get_reroll_preview(0)
	var current := HandCalculator.evaluate([5, 5]).total_score
	var best := HandCalculator.evaluate([6, 6]).total_score
	var worst := HandCalculator.evaluate([1, 1]).total_score

	if preview.current_score != current:
		_fail("controller preview current score", current, preview.current_score)
	if preview.delta_up != best - current:
		_fail("controller preview delta_up", best - current, preview.delta_up)
	if preview.delta_down != worst - current:
		_fail("controller preview delta_down", worst - current, preview.delta_down)
	controller.free()


func _number_face(value: int) -> Resource:
	var face: Resource = NumberFaceScript.new()
	face.value = value
	face.display_name = str(value)
	return face


func _highest_face() -> Resource:
	var face: Resource = SpecialFaceScript.new()
	var property: Resource = ChangeToHighestPropertyScript.new()
	var properties: Array[Resource] = [property]
	face.properties = properties
	return face


func _typed_ints(values: Array) -> Array[int]:
	var typed_values: Array[int] = []
	for value in values:
		typed_values.append(int(value))
	return typed_values


func _fail(label: String, expected: int, got: int) -> void:
	_failed += 1
	push_error("%s: expected %d got %d" % [label, expected, got])


func _fail_array(label: String, expected: Array, got: Array) -> void:
	_failed += 1
	push_error("%s: expected %s got %s" % [label, expected, got])


func _fail_string(label: String, expected: String, got: String) -> void:
	_failed += 1
	push_error("%s: expected %s got %s" % [label, expected, got])


func _fail_bool(label: String, expected: bool, got: bool) -> void:
	_failed += 1
	push_error("%s: expected %s got %s" % [label, expected, got])
