extends Node

const HandEvaluation := preload("res://scripts/core/hand_evaluation.gd")
const HandStep := preload("res://scripts/core/hand_step.gd")

const ROW_TEXT_COLOR := Color(0.18, 0.15, 0.12, 1)
const SCORE_TEXT_COLOR := Color(0.72, 0.42, 0.08, 1.0)
const ROW_FONT_SIZE := 15
const EMPTY_HINT_COLOR := Color(0.45, 0.4, 0.35, 1)

var _list_container: VBoxContainer
var _entry_count := 0


func setup(list_container: VBoxContainer) -> void:
	_list_container = list_container
	clear()


func clear() -> void:
	_entry_count = 0
	if _list_container == null:
		return
	_clear_rows()
	_add_empty_hint()


func add_roll(evaluation: HandEvaluation) -> void:
	if _list_container == null or evaluation == null:
		return
	if _entry_count == 0:
		_clear_rows()

	_entry_count += 1
	_add_roll_row(_entry_count, _get_hand_label(evaluation), evaluation.total_score)


func show_summaries(_summaries: Array[Dictionary]) -> void:
	pass


func _clear_rows() -> void:
	for child in _list_container.get_children():
		child.queue_free()


func _get_hand_label(evaluation: HandEvaluation) -> String:
	if evaluation.steps.is_empty():
		return "기본 x%d" % evaluation.hand_value_sum
	var step: HandStep = evaluation.steps[0]
	return "%s x%d" % [step.display_ko, evaluation.hand_value_sum]


func _add_empty_hint() -> void:
	var label := Label.new()
	label.layout_mode = 2
	label.text = "이번 층 기록 없음"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", EMPTY_HINT_COLOR)
	label.add_theme_font_size_override("font_size", ROW_FONT_SIZE)
	_list_container.add_child(label)


func _add_roll_row(index: int, hand_label: String, score: int) -> void:
	var row := HBoxContainer.new()
	row.layout_mode = 2
	row.add_theme_constant_override("separation", 6)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var hand := Label.new()
	hand.layout_mode = 2
	hand.text = "%02d. %s" % [index, hand_label]
	hand.clip_text = true
	hand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hand.add_theme_color_override("font_color", ROW_TEXT_COLOR)
	hand.add_theme_font_size_override("font_size", ROW_FONT_SIZE)
	row.add_child(hand)

	var score_label := Label.new()
	score_label.layout_mode = 2
	score_label.text = "+%d" % score
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_label.add_theme_color_override("font_color", SCORE_TEXT_COLOR)
	score_label.add_theme_font_size_override("font_size", ROW_FONT_SIZE)
	row.add_child(score_label)

	_list_container.add_child(row)
