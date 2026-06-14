extends SceneTree

const CatalogService := preload("res://scripts/core/dice_catalog_service.gd")
const NumberFaceScript := preload("res://scripts/core/number_face.gd")

var _failed := 0


func _init() -> void:
	CatalogService.reset_for_tests()
	var catalog = CatalogService.shared()

	_expect_basic_die(catalog)
	_expect_triple_h_die(catalog)
	_expect_triple_l_die(catalog)
	_expect_triple_v_die(catalog)
	_expect_roster_preview_faces(catalog)
	_expect_starter_loadout(catalog)
	_expect_unknown_id_returns_null(catalog)

	if _failed > 0:
		push_error("Dice catalog spec tests failed: %d" % _failed)
	quit(_failed)


func _expect_basic_die(catalog) -> void:
	var die: Resource = catalog.get_dice("dice_basic")
	if die == null:
		_fail_bool("basic die exists", true, false)
		return
	if die.get_face_count() != 6:
		_fail("basic face count", 6, die.get_face_count())
	if die.get_face_values() != [1, 2, 3, 4, 5, 6]:
		_fail_array("basic face values", [1, 2, 3, 4, 5, 6], die.get_face_values())


func _expect_triple_h_die(catalog) -> void:
	var die: Resource = catalog.get_dice("dice_triple_h")
	if die == null:
		_fail_bool("triple h die exists", true, false)
		return
	if die.get_face_count() != 6:
		_fail("triple h face count", 6, die.get_face_count())

	var faces: Array[Resource] = die.get_faces()
	var one := faces[3]
	var two := faces[4]
	var three := faces[5]
	var trio: Array[Resource] = [one, two, three]
	var resolved: Array = die.resolve_face_values(trio)
	if resolved != [1, 1, 1]:
		_fail_array("triple h number faces", [1, 1, 1], resolved)

	var board: Array[Resource] = faces.duplicate()
	var values: Array = die.resolve_face_values(board)
	if values != [1, 1, 1, 1, 1, 1]:
		_fail_array("triple h board with only ones", [1, 1, 1, 1, 1, 1], values)

	var mixed_faces: Array[Resource] = []
	mixed_faces.append(_make_number_face(2))
	mixed_faces.append(_make_number_face(5))
	mixed_faces.append(faces[0])
	var mixed_values: Array = die.resolve_face_values(mixed_faces)
	if mixed_values != [2, 5, 5]:
		_fail_array("triple h change to highest", [2, 5, 5], mixed_values)


func _expect_triple_l_die(catalog) -> void:
	var die: Resource = catalog.get_dice("dice_triple_l")
	if die == null:
		_fail_bool("triple l die exists", true, false)
		return

	var faces: Array[Resource] = die.get_faces()
	var trio: Array[Resource] = [faces[3], faces[4], faces[5]]
	if die.resolve_face_values(trio) != [3, 3, 3]:
		_fail_array("triple l number faces", [3, 3, 3], die.resolve_face_values(trio))

	var mixed_faces: Array[Resource] = []
	mixed_faces.append(_make_number_face(2))
	mixed_faces.append(_make_number_face(5))
	mixed_faces.append(faces[0])
	if die.resolve_face_values(mixed_faces) != [2, 5, 2]:
		_fail_array("triple l change to lowest", [2, 5, 2], die.resolve_face_values(mixed_faces))


func _expect_triple_v_die(catalog) -> void:
	var die: Resource = catalog.get_dice("dice_triple_v")
	if die == null:
		_fail_bool("triple v die exists", true, false)
		return

	var faces: Array[Resource] = die.get_faces()
	var trio: Array[Resource] = [faces[3], faces[4], faces[5]]
	if die.resolve_face_values(trio) != [2, 2, 2]:
		_fail_array("triple v number faces", [2, 2, 2], die.resolve_face_values(trio))

	var board_faces: Array[Resource] = []
	board_faces.append(_make_number_face(3))
	board_faces.append(_make_number_face(4))
	board_faces.append(faces[0])
	if die.resolve_face_values(board_faces) != [3, 4, 2]:
		_fail_array("triple v change to missing", [3, 4, 2], die.resolve_face_values(board_faces))


func _expect_roster_preview_faces(catalog) -> void:
	var basic: Resource = catalog.get_dice("dice_basic")
	var basic_face: Resource = basic.get_roster_preview_face()
	if basic_face == null or not basic_face.is_number() or basic_face.get_base_number_value() != 6:
		_fail_bool("basic roster preview is pip 6", true, false)

	var triple_h: Resource = catalog.get_dice("dice_triple_h")
	var h_face: Resource = triple_h.get_roster_preview_face()
	if h_face == null or h_face.is_number():
		_fail_bool("triple h roster preview is special", true, false)
	if h_face.get_display_text({}) != "H":
		_fail_string("triple h roster preview display", "H", h_face.get_display_text({}))

	var triple_l: Resource = catalog.get_dice("dice_triple_l")
	var l_face: Resource = triple_l.get_roster_preview_face()
	if l_face == null or l_face.is_number() or l_face.get_display_text({}) != "L":
		_fail_bool("triple l roster preview is L", true, false)

	var triple_v: Resource = catalog.get_dice("dice_triple_v")
	var v_face: Resource = triple_v.get_roster_preview_face()
	if v_face == null or v_face.is_number() or v_face.get_display_text({}) != "V":
		_fail_bool("triple v roster preview is V", true, false)


func _expect_starter_loadout(catalog) -> void:
	var starter: Array = catalog.get_starter_owned_ids()
	if starter.size() != 4:
		_fail("starter count", 4, starter.size())
	for dice_id in starter:
		if dice_id != "dice_basic":
			_fail_bool("starter only basic dice", true, false)
			break


func _expect_unknown_id_returns_null(catalog) -> void:
	if catalog.get_dice("dice_missing") != null:
		_fail_bool("unknown id null", true, false)


func _make_number_face(value: int) -> Resource:
	var face: Resource = NumberFaceScript.new()
	face.value = value
	return face


func _fail(label: String, expected: int, actual: int) -> void:
	_failed += 1
	push_error("%s: expected %d got %d" % [label, expected, actual])


func _fail_bool(label: String, expected: bool, actual: bool) -> void:
	_failed += 1
	push_error("%s: expected %s got %s" % [label, str(expected), str(actual)])


func _fail_string(label: String, expected: String, actual: String) -> void:
	if expected == actual:
		return
	_failed += 1
	push_error("%s: expected %s got %s" % [label, expected, actual])


func _fail_array(label: String, expected: Array, actual: Array) -> void:
	if expected == actual:
		return
	_failed += 1
	push_error("%s: expected %s got %s" % [label, str(expected), str(actual)])
