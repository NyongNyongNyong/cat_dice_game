extends SceneTree

const DiceRosterScript := preload("res://scripts/core/dice_roster.gd")
const CatalogService := preload("res://scripts/core/dice_catalog_service.gd")

var _failed := 0


func _init() -> void:
	CatalogService.reset_for_tests()
	CatalogService.shared().reload()

	_expect_starting_roster()
	_expect_replace_with_catalog_id()

	if _failed > 0:
		push_error("Dice roster spec tests failed: %d" % _failed)
	quit(_failed)


func _expect_starting_roster() -> void:
	var roster: RefCounted = DiceRosterScript.new()
	roster.reset_to_starting()

	if roster.get_count() != 4:
		_fail("starting count", 4, roster.get_count())
	if roster.get_owned_dice().size() != 4:
		_fail("starting owned size", 4, roster.get_owned_dice().size())

	var die: Resource = roster.get_dice_resource(0)
	if die == null or not die.has_method("get_face_count"):
		_fail_bool("starting die resource", true, die != null)
	elif die.get_face_count() != 6:
		_fail("starting die face count", 6, die.get_face_count())


func _expect_replace_with_catalog_id() -> void:
	var roster: RefCounted = DiceRosterScript.new()
	roster.reset_to_starting()

	if not roster.replace_at_index(1, "dice_triple_h"):
		_fail_bool("replace triple h", true, false)

	var replaced: Resource = roster.get_dice_resource(1)
	var triple_h: Resource = CatalogService.shared().get_dice("dice_triple_h")
	if replaced != triple_h:
		_fail_bool("replaced resource is triple h die", true, replaced == triple_h)
	if replaced != null and replaced.get_face_count() != 6:
		_fail("replaced face count", 6, replaced.get_face_count())

	if roster.replace_at_index(99, "dice_triple_h"):
		_fail_bool("replace invalid index", false, true)
	if roster.replace_at_index(0, "dice_missing"):
		_fail_bool("replace unknown id", false, true)


func _fail(label: String, expected, actual) -> void:
	_failed += 1
	push_error("%s: expected %s got %s" % [label, str(expected), str(actual)])


func _fail_bool(label: String, expected: bool, actual: bool) -> void:
	_failed += 1
	push_error("%s: expected %s got %s" % [label, str(expected), str(actual)])
