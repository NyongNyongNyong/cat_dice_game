extends RefCounted

const REGISTRY_PATH := "res://data/registry.json"
const REQUIRED_FACE_COUNT := 6
const FALLBACK_STARTER_IDS: Array[String] = [
	"dice_basic",
	"dice_basic",
	"dice_basic",
	"dice_basic",
]

const NumberFaceScript := preload("res://scripts/core/number_face.gd")
const SpecialFaceScript := preload("res://scripts/core/special_face.gd")
const DiceResourceScript := preload("res://scripts/core/dice_resource.gd")
const ChangeToHighestPropertyScript := preload(
	"res://scripts/core/face_properties/change_to_highest_property.gd"
)

static var _shared = null

var _dice_by_id: Dictionary = {}
var _display_names: Dictionary = {}
var _starter_owned_ids: Array[String] = []
var _loaded := false


static func shared():
	if _shared == null:
		var script: GDScript = load("res://scripts/core/dice_catalog_service.gd") as GDScript
		_shared = script.new()
		_shared.reload()
	return _shared


static func reset_for_tests() -> void:
	_shared = null


func reload() -> void:
	_dice_by_id.clear()
	_display_names.clear()
	_starter_owned_ids.clear()
	_loaded = false
	_load_catalog()


func get_dice(dice_id: String) -> Resource:
	_ensure_loaded()
	return _dice_by_id.get(dice_id)


func has_dice(dice_id: String) -> bool:
	_ensure_loaded()
	return _dice_by_id.has(dice_id)


func get_display_name(dice_id: String) -> String:
	_ensure_loaded()
	if _display_names.has(dice_id):
		return str(_display_names[dice_id])
	return dice_id


func get_starter_owned_ids() -> Array[String]:
	_ensure_loaded()
	return _starter_owned_ids.duplicate()


func get_required_face_count() -> int:
	return REQUIRED_FACE_COUNT


func _ensure_loaded() -> void:
	if not _loaded:
		reload()


func _load_catalog() -> void:
	var dice_path := _resolve_catalog_path("dice")
	if dice_path.is_empty():
		push_error("DiceCatalog: dice catalog path missing in registry.json")
		_apply_fallback_starter()
		_loaded = true
		return

	_load_dice_defs(dice_path)
	_load_starter_loadout(_resolve_catalog_path("starter_loadout"))
	if _starter_owned_ids.is_empty():
		_apply_fallback_starter()
	_loaded = true


func _resolve_catalog_path(key: String) -> String:
	var registry_text := FileAccess.get_file_as_string(REGISTRY_PATH)
	if registry_text.is_empty():
		return ""

	var registry = JSON.parse_string(registry_text)
	if typeof(registry) != TYPE_DICTIONARY:
		return ""

	var catalogs: Dictionary = registry.get("catalogs", {})
	var relative_path: String = str(catalogs.get(key, ""))
	if relative_path.is_empty():
		return ""
	return "res://data/%s" % relative_path


func _load_dice_defs(path: String) -> void:
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("DiceCatalog: failed to read %s" % path)
		return

	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		push_error("DiceCatalog: invalid JSON in %s" % path)
		return

	for dice_def in data.get("dice", []):
		if typeof(dice_def) != TYPE_DICTIONARY:
			continue
		_register_dice_def(dice_def)


func _load_starter_loadout(path: String) -> void:
	if path.is_empty():
		return

	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("DiceCatalog: failed to read starter loadout %s" % path)
		return

	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		push_error("DiceCatalog: invalid starter loadout JSON")
		return

	for dice_id in data.get("owned_dice_ids", []):
		_starter_owned_ids.append(str(dice_id))


func _register_dice_def(dice_def: Dictionary) -> void:
	var dice_id: String = str(dice_def.get("id", ""))
	if dice_id.is_empty():
		push_error("DiceCatalog: dice entry missing id")
		return

	var faces_data: Array = dice_def.get("faces", [])
	if faces_data.size() != REQUIRED_FACE_COUNT:
		push_error(
			"DiceCatalog: %s must have %d faces (got %d)" % [
				dice_id, REQUIRED_FACE_COUNT, faces_data.size()
			]
		)
		return

	var built_faces: Array[Resource] = []
	for face_def in faces_data:
		if typeof(face_def) != TYPE_DICTIONARY:
			push_error("DiceCatalog: invalid face entry in %s" % dice_id)
			return
		var face = _build_face(face_def)
		if face == null:
			push_error("DiceCatalog: failed to build face for %s" % dice_id)
			return
		built_faces.append(face)

	var die: Resource = DiceResourceScript.new()
	die.id = StringName(dice_id)
	die.display_name = str(dice_def.get("display_name", dice_id))
	die.faces = built_faces
	var empty_face_values: Array[int] = []
	die.face_values = empty_face_values

	_dice_by_id[dice_id] = die
	var display_ko: String = str(dice_def.get("display_ko", ""))
	if display_ko.is_empty():
		display_ko = die.display_name
	_display_names[dice_id] = display_ko


func _build_face(face_def: Dictionary) -> Resource:
	var kind: String = str(face_def.get("kind", ""))
	match kind:
		"number":
			var value: int = int(face_def.get("value", 1))
			var number_face: Resource = NumberFaceScript.new()
			number_face.value = value
			return number_face
		"special":
			return _build_special_face(face_def)
		_:
			push_error("DiceCatalog: unknown face kind '%s'" % kind)
			return null


func _build_special_face(face_def: Dictionary) -> Resource:
	var property_id: String = str(face_def.get("property_id", ""))
	var property: Resource = _build_property(property_id)
	if property == null:
		return null

	var special_face: Resource = SpecialFaceScript.new()
	special_face.symbol_id = StringName(property_id)
	special_face.display_name = property_id
	var properties: Array[Resource] = [property]
	special_face.properties = properties
	return special_face


func _build_property(property_id: String) -> Resource:
	match property_id:
		"change_to_highest":
			return ChangeToHighestPropertyScript.new()
		_:
			push_error("DiceCatalog: unknown property_id '%s'" % property_id)
			return null


func _apply_fallback_starter() -> void:
	_starter_owned_ids = FALLBACK_STARTER_IDS.duplicate()
	if not _dice_by_id.has("dice_basic"):
		_register_builtin_basic_die()


func _register_builtin_basic_die() -> void:
	var die: Resource = DiceResourceScript.new()
	die.id = &"dice_basic"
	die.display_name = "Basic Die"
	var empty_faces: Array[Resource] = []
	die.faces = empty_faces
	die.face_values = [1, 2, 3, 4, 5, 6]
	_dice_by_id["dice_basic"] = die
	_display_names["dice_basic"] = "기본 주사위"
