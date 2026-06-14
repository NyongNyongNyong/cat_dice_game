extends SceneTree

const DiceRosterScript := preload("res://scripts/core/dice_roster.gd")
const CatalogService := preload("res://scripts/core/dice_catalog_service.gd")

var _failed := 0


func _init() -> void:
	CatalogService.reset_for_tests()
	CatalogService.shared().reload()

	_expect_starting_roster()
	_expect_replace_with_catalog_id()
	_expect_swap_indices()

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
	if replaced == null or str(replaced.id) != "dice_triple_h":
		_fail_bool("replaced resource is triple h die", true, false)
	if replaced != null and replaced.get_face_count() != 6:
		_fail("replaced face count", 6, replaced.get_face_count())

	var faces: Array[Resource] = replaced.get_faces()
	var number_face_count := 0
	for face in faces:
		if face != null and face.has_method("is_number") and face.is_number():
			number_face_count += 1
	if number_face_count != 3:
		_fail("triple h number faces", 3, number_face_count)

	if roster.replace_at_index(99, "dice_triple_h"):
		_fail_bool("replace invalid index", false, true)
	if roster.replace_at_index(0, "dice_missing"):
		_fail_bool("replace unknown id", false, true)


func _expect_swap_indices() -> void:
	var roster: RefCounted = DiceRosterScript.new()
	roster.reset_to_starting()

	if not roster.replace_at_index(1, "dice_triple_h"):
		_fail_bool("prepare swap custom die", true, false)
	if not roster.swap_indices(0, 1):
		_fail_bool("swap valid indices", true, false)

	var first: Resource = roster.get_dice_resource(0)
	var second: Resource = roster.get_dice_resource(1)
	if first == null or str(first.id) != "dice_triple_h":
		_fail_bool("swapped first die is custom die", true, false)
	if second == null or str(second.id) != "dice_basic":
		_fail_bool("swapped second die is starting die", true, false)

	if roster.swap_indices(-1, 0):
		_fail_bool("swap invalid first index", false, true)
	if roster.swap_indices(0, 99):
		_fail_bool("swap invalid second index", false, true)
	if not roster.swap_indices(0, 0):
		_fail_bool("swap same index succeeds", true, false)


func _fail(label: String, expected, actual) -> void:
	_failed += 1
	push_error("%s: expected %s got %s" % [label, str(expected), str(actual)])


func _fail_bool(label: String, expected: bool, actual: bool) -> void:
	_failed += 1
	push_error("%s: expected %s got %s" % [label, str(expected), str(actual)])
