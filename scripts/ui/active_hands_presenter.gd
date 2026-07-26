extends Node

const HandEvaluation := preload("res://scripts/core/hand_evaluation.gd")
const HandStep := preload("res://scripts/core/hand_step.gd")
const ACTIVE_HAND_ROW_SCENE := preload("res://scenes/ui/active_hand_row.tscn")
const ActiveHandRowScript := preload("res://scripts/ui/active_hand_row.gd")

var _list_container: VBoxContainer
var _empty_hint: Control
var _entry_count := 0
var _rows: Array[Control] = []


func setup(list_container: VBoxContainer, empty_hint: Control = null) -> void:
	_list_container = list_container
	_empty_hint = empty_hint
	clear()


func clear() -> void:
	_entry_count = 0
	if _list_container == null:
		return
	_clear_rows()
	_set_empty_hint_visible(true)


func add_roll(evaluation: HandEvaluation) -> void:
	if _list_container == null or evaluation == null:
		return
	if _entry_count == 0:
		_clear_rows()
		_set_empty_hint_visible(false)

	_entry_count += 1
	_add_roll_row(_entry_count, _get_hand_label(evaluation), evaluation.total_score)


func show_summaries(_summaries: Array[Dictionary]) -> void:
	pass


# 코드가 만든 행만 지운다. %ActiveHandsList에 장식 노드를 두어도 유지된다.
func _clear_rows() -> void:
	for row in _rows:
		if is_instance_valid(row):
			row.queue_free()
	_rows.clear()


func _set_empty_hint_visible(on: bool) -> void:
	if _empty_hint != null and is_instance_valid(_empty_hint):
		_empty_hint.visible = on


func _get_hand_label(evaluation: HandEvaluation) -> String:
	if evaluation.steps.is_empty():
		return "기본 x%d" % evaluation.hand_value_sum
	var step: HandStep = evaluation.steps[0]
	return "%s x%d" % [step.display_ko, evaluation.hand_value_sum]


func _add_roll_row(index: int, hand_label: String, score: int) -> void:
	var row: ActiveHandRowScript = ACTIVE_HAND_ROW_SCENE.instantiate()
	_rows.append(row)
	_list_container.add_child(row)
	row.set_entry(index, hand_label, score)
