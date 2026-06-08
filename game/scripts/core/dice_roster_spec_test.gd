extends SceneTree

const DiceRosterScript := preload("res://scripts/core/dice_roster.gd")
const DiceResourceScript := preload("res://scripts/core/dice_resource.gd")

var _failed := 0


func _init() -> void:
	_expect_starting_roster()
	_expect_replace_with_h()

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


func _expect_replace_with_h() -> void:
	var roster: RefCounted = DiceRosterScript.new()
	roster.reset_to_starting()

	if not roster.replace_with_h_at(1):
		_fail_bool("replace with h", true, false)

	var replaced: Resource = roster.get_dice_resource(1)
	var h_die: Resource = roster.get_h_replacement_resource()
	if replaced != h_die:
		_fail_bool("replaced resource is h die", true, replaced == h_die)

	if roster.replace_with_h_at(99):
		_fail_bool("replace invalid index", false, true)


func _fail(label: String, expected, actual) -> void:
	_failed += 1
	push_error("%s: expected %s got %s" % [label, str(expected), str(actual)])


func _fail_bool(label: String, expected: bool, actual: bool) -> void:
	_failed += 1
	push_error("%s: expected %s got %s" % [label, str(expected), str(actual)])
