extends SceneTree

## 코드가 %UniqueName으로 찾는 핵심 UI 노드가 씬에 남아 있는지 확인한다.
##
## 에디터에서 이 노드들을 다른 Panel·Container 아래로 옮기거나 꾸미는 것은 자유다.
## 하지만 **이름을 바꾸거나, 지우거나, Access as Unique Name을 끄면** 이 테스트가
## 실패한다. 상세: docs/design/systems/ui-editor-friendly.md
##
## .tscn 텍스트를 읽어서 검사한다. 씬을 load()하면 붙어 있는 스크립트까지 컴파일되는데
## --script 모드에는 Autoload가 없어 실패하기 때문이다.

const REQUIRED_UNIQUE_NODES: Dictionary = {
	"res://scenes/game/main.tscn": ["UI"],
	"res://scenes/game/run_scene.tscn": [
		"FloorLabel",
		"GoldLabel",
		"TargetScoreLabel",
		"CurrentScoreLabel",
		"TargetProgressBar",
		"ProgressValueLabel",
		"StatusLabel",
		"DiceRow",
		"BoardGrid",
		"RosterTray",
		"ScoreOverlay",
		"PopupOverlay",
		"LeftValue",
		"RightValue",
		"RollLever",
		"NextFloorButton",
		"ActiveHandsList",
		"ActiveHandsEmptyHint",
		"RoundController",
		"RollPhasePresenter",
		"ScorePhasePresenter",
		"FacePreviewPresenter",
		"ActiveHandsPresenter",
	],
	"res://scenes/game/shop_scene.tscn": [
		"FloorLabel",
		"GoldLabel",
		"StatusLabel",
		"ShopDiceRow",
		"PoolGrid",
		"PendingLabel",
		"ConfirmButton",
		"ContinueButton",
		"PopupOverlay",
		"DiceShopPresenter",
		"FacePreviewPresenter",
	],
	"res://scenes/ui/dice_slot.tscn": ["DiceHolder"],
	"res://scenes/ui/shop_offer_die.tscn": ["DiceHolder"],
	"res://scenes/ui/shop_pool_cell.tscn": ["DiceHolder"],
	"res://scenes/ui/active_hand_row.tscn": ["HandLabel", "ScoreLabel"],
	"res://scenes/ui/face_preview_tooltip.tscn": ["Content", "FacesRow", "DescBox"],
}

var _failed := 0


func _init() -> void:
	for scene_path in REQUIRED_UNIQUE_NODES:
		_check_scene(str(scene_path), REQUIRED_UNIQUE_NODES[scene_path])

	if _failed > 0:
		push_error("UI scene spec tests failed: %d" % _failed)
	quit(_failed)


func _check_scene(scene_path: String, required_names: Array) -> void:
	var unique_names := _read_unique_node_names(scene_path)
	if unique_names.is_empty():
		_fail("%s: no unique-name nodes found (파일을 읽지 못했거나 전부 지워졌다)" % scene_path)
		return

	for node_name in required_names:
		if not unique_names.has(node_name):
			_fail("%s: %%%s 가 없다 (이름 변경·삭제·Unique Name 해제)" % [scene_path, node_name])


## `unique_name_in_owner = true`가 붙은 노드 이름 집합.
func _read_unique_node_names(scene_path: String) -> Dictionary:
	var file := FileAccess.open(scene_path, FileAccess.READ)
	if file == null:
		return {}

	var names: Dictionary = {}
	var current_name := ""
	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.begins_with("[node "):
			current_name = _parse_node_name(line)
		elif line == "unique_name_in_owner = true" and not current_name.is_empty():
			names[current_name] = true
	file.close()
	return names


func _parse_node_name(node_line: String) -> String:
	var marker := "name=\""
	var start := node_line.find(marker)
	if start < 0:
		return ""
	start += marker.length()
	var end := node_line.find("\"", start)
	if end < 0:
		return ""
	return node_line.substr(start, end - start)


func _fail(message: String) -> void:
	_failed += 1
	push_error(message)
