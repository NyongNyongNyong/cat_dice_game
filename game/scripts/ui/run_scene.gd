extends Control

const DICE_SCENE := preload("res://scenes/dice/dice.tscn")
const DICE_SLOT_SCENE := preload("res://scenes/ui/dice_slot.tscn")
const GoldCalculator := preload("res://scripts/core/gold_calculator.gd")
const RollLever := preload("res://scripts/ui/roll_lever.gd")
const RoundController := preload("res://scripts/core/round_controller.gd")
const RollPhasePresenter := preload("res://scripts/ui/roll_phase_presenter.gd")
const ScorePhasePresenter := preload("res://scripts/ui/score_phase_presenter.gd")
const HandEvaluation := preload("res://scripts/core/hand_evaluation.gd")
const RoundPhase := preload("res://scripts/core/round_phase.gd")
const TARGET_PROGRESS_COLORS: Array[Color] = [
	Color(0.26, 0.63, 0.52, 1.0),
	Color(0.95, 0.55, 0.18, 1.0),
	Color(0.93, 0.78, 0.22, 1.0),
	Color(0.25, 0.58, 0.9, 1.0),
	Color(0.55, 0.38, 0.88, 1.0),
	Color(0.9, 0.28, 0.45, 1.0),
]
const TARGET_PROGRESS_FULL_DURATION := 0.38
const TARGET_PROGRESS_PARTIAL_MIN_DURATION := 0.16
const TARGET_PROGRESS_SEGMENT_PAUSE := 0.08
const TARGET_PROGRESS_MAX_SEGMENTS := 24
const TARGET_REWARD_FLOAT_DURATION := 0.62

@onready var _floor_label: Label = %FloorLabel
@onready var _gold_label: Label = %GoldLabel
@onready var _target_label: Label = %TargetScoreLabel
@onready var _current_label: Label = %CurrentScoreLabel
@onready var _target_progress_bar: ProgressBar = %TargetProgressBar
@onready var _target_progress_value_label: Label = %ProgressValueLabel
@onready var _status_label: Label = %StatusLabel
@onready var _dice_row: Control = %DiceRow
@onready var _board_grid: GridContainer = %BoardGrid
@onready var _roster_tray: HBoxContainer = %RosterTray
@onready var _popup_overlay: Control = %ScoreOverlay
@onready var _left_value: Label = %LeftValue
@onready var _right_value: Label = %RightValue
@onready var _roll_lever: RollLever = %RollLever
@onready var _next_floor_button: Button = %NextFloorButton
@onready var _dice_popup_layer: Control = %PopupOverlay
@onready var _round: RoundController = %RoundController
@onready var _roll_presenter: RollPhasePresenter = %RollPhasePresenter
@onready var _score_presenter: ScorePhasePresenter = %ScorePhasePresenter
@onready var _reroll_preview_presenter: Node = %RerollPreviewPresenter
@onready var _active_hands_list: VBoxContainer = %ActiveHandsList
@onready var _active_hands_presenter: Node = %ActiveHandsPresenter

var _board_cells: Array = []
var _tray_chips: Array = []
var _dice_views: Array[Control] = []
var _selected_owned_index := -1
var _lever_speed_multiplier := 0.0
var _lever_loop_running := false
var _is_animating_target_progress := false
var _target_progress_tween: Tween
var _roll_slot: Control


func _ready() -> void:
	_setup_round_flow()
	if not RunManager.is_run_started():
		RunManager.start_run()
	_build_board()
	_refresh_board()
	_refresh_tray()
	_prepare_round_dice()
	if not RunManager.run_finished:
		_round.begin_round()
	_sync_ui()


func _setup_round_flow() -> void:
	_roll_slot = _dice_row
	_roll_presenter.setup(_roll_slot, _dice_row)
	_active_hands_presenter.setup(_active_hands_list)
	_score_presenter.setup(
		_dice_row, _popup_overlay, _left_value, _right_value, _status_label
	)
	_reroll_preview_presenter.setup(_dice_popup_layer)
	_reroll_preview_presenter.set_active(false)

	_round.phase_changed.connect(_on_round_phase_changed)
	_round.dice_rolled.connect(_on_dice_rolled)
	_round.score_ready.connect(_on_score_ready)
	_round.round_reset.connect(_on_round_reset)

	RunManager.floor_changed.connect(_on_floor_changed)
	RunManager.score_changed.connect(_on_score_changed)
	RunManager.chips_changed.connect(_on_chips_changed)
	RunManager.gold_changed.connect(_on_gold_changed)
	RunManager.run_completed.connect(_on_run_completed)
	RunManager.roster_changed.connect(_on_roster_changed)
	RunManager.board_changed.connect(_on_board_changed)

	_roll_lever.speed_changed.connect(_on_roll_lever_speed_changed)
	_next_floor_button.pressed.connect(_on_next_floor_pressed)


# --- Board + tray -----------------------------------------------------------

func _build_board() -> void:
	for child in _board_grid.get_children():
		child.queue_free()
	_board_cells.clear()
	_board_grid.columns = RunManager.BOARD_COLS

	for cell in RunManager.BOARD_CELLS:
		var slot = DICE_SLOT_SCENE.instantiate()
		slot.set_slot_index(cell)
		_board_grid.add_child(slot)
		slot.set_drag_enabled(false)
		slot.clicked.connect(_on_board_cell_clicked)
		_board_cells.append(slot)


func _refresh_board() -> void:
	for cell in _board_cells.size():
		var slot = _board_cells[cell]
		slot.clear_dice_view()
		slot.set_locked(not RunManager.is_slot_unlocked(cell))
		slot.set_selected(false)

		var owned_index := RunManager.get_owned_index_at(cell)
		if owned_index < 0:
			continue
		var resource := _round_owned_resource(owned_index)
		var dice: Control = DICE_SCENE.instantiate()
		slot.set_dice_view(dice)
		_apply_preview_face(dice, resource)


func _refresh_tray() -> void:
	for child in _roster_tray.get_children():
		child.queue_free()
	_tray_chips.clear()

	var placed := RunManager.get_placed_owned_indices()
	for owned_index in RunManager.get_owned_dice_count():
		if placed.has(owned_index):
			continue
		var chip = DICE_SLOT_SCENE.instantiate()
		chip.set_slot_index(owned_index)
		_roster_tray.add_child(chip)
		chip.set_drag_enabled(false)
		chip.set_selected(owned_index == _selected_owned_index)
		chip.clicked.connect(_on_tray_chip_clicked)

		var dice: Control = DICE_SCENE.instantiate()
		chip.set_dice_view(dice)
		_apply_preview_face(dice, _round_owned_resource(owned_index))
		_tray_chips.append(chip)


func _round_owned_resource(owned_index: int) -> Resource:
	var owned := RunManager.get_owned_dice()
	if owned_index < 0 or owned_index >= owned.size():
		return null
	return owned[owned_index]


func _apply_preview_face(dice: Control, resource: Resource) -> void:
	if resource == null:
		dice.show_placeholder()
		return
	var preview_face: Resource = resource.get_roster_preview_face()
	if preview_face == null:
		dice.show_placeholder()
		return
	dice.set_face(preview_face, resource.get_roster_preview_value())


func _can_edit_board() -> bool:
	return (
		not RunManager.run_finished
		and _is_lever_stopped()
		and (_round.phase == RoundPhase.Phase.IDLE or _round.phase == RoundPhase.Phase.REROLL_READY)
	)


func _on_board_cell_clicked(cell: int) -> void:
	if not _can_edit_board():
		return
	if not RunManager.is_slot_unlocked(cell):
		return

	var owned_index := RunManager.get_owned_index_at(cell)
	if owned_index >= 0:
		RunManager.clear_cell(cell)
		_selected_owned_index = -1
		return
	if _selected_owned_index < 0:
		return
	RunManager.place_die(_selected_owned_index, cell)
	_selected_owned_index = -1


func _on_tray_chip_clicked(owned_index: int) -> void:
	if not _can_edit_board():
		return
	if _selected_owned_index == owned_index:
		_selected_owned_index = -1
	else:
		_selected_owned_index = owned_index
	for chip in _tray_chips:
		chip.set_selected(chip.slot_index == _selected_owned_index)


func _on_board_changed() -> void:
	_refresh_board()
	_refresh_tray()
	_prepare_round_dice()
	_sync_ui()


func _prepare_round_dice() -> void:
	_round.dice_loadout = null
	_round.dice_resources = RunManager.get_placed_dice()
	_dice_views.clear()
	for cell in _board_cells.size():
		if RunManager.get_owned_index_at(cell) < 0:
			continue
		var dice_view: Control = _board_cells[cell].get_dice_view()
		if dice_view != null:
			_dice_views.append(dice_view)
	_score_presenter.set_dice_views(_dice_views)
	_roll_presenter.set_dice_views(_dice_views)


# --- Roll / score flow ------------------------------------------------------

func _on_roll_lever_speed_changed(multiplier: float) -> void:
	if RunManager.run_finished:
		return
	_lever_speed_multiplier = multiplier
	_apply_lever_speed()
	if _lever_speed_multiplier > 0.0:
		_selected_owned_index = -1
		_prepare_round_dice()
		_run_lever_loop()
	_sync_ui()


func _run_lever_loop() -> void:
	if _lever_loop_running:
		return
	_lever_loop_running = true

	while (
		_lever_speed_multiplier > 0.0
		and RunManager.get_placed_count() > 0
		and _round.can_roll()
		and not RunManager.run_finished
	):
		_round.roll()
		while _round.phase == RoundPhase.Phase.ROLLING or _round.phase == RoundPhase.Phase.SCORING:
			await _round.phase_changed
		await get_tree().process_frame

	_lever_loop_running = false
	_sync_ui()


func _apply_lever_speed() -> void:
	var speed := maxf(_lever_speed_multiplier, 1.0)
	if _roll_presenter.has_method("set_speed_multiplier"):
		_roll_presenter.set_speed_multiplier(speed)
	if _score_presenter.has_method("set_speed_multiplier"):
		_score_presenter.set_speed_multiplier(speed)


func _on_dice_rolled(values: Array[int]) -> void:
	await _roll_presenter.play_roll(_round.dice_faces, values, _get_roll_face_candidates())
	await _play_dice_face_effects(_round.dice_faces, values)
	_round.complete_roll_presentation()


func _on_score_ready(evaluation: HandEvaluation) -> void:
	await _score_presenter.play(evaluation, false, -1, _round.dice_faces)
	_is_animating_target_progress = true
	var previous_score := RunManager.current_score
	RunManager.add_score(evaluation.total_score)
	if _active_hands_presenter.has_method("add_roll"):
		_active_hands_presenter.add_roll(evaluation)
	await _animate_target_progress(previous_score, RunManager.current_score)
	_is_animating_target_progress = false
	_round.complete_score_presentation()
	_show_dice_faces(_round.dice_faces, evaluation.dice_values)
	_sync_ui()


func _show_dice_faces(faces: Array, values: Array[int]) -> void:
	_dice_row.visible = true
	for i in values.size():
		if i < faces.size() and faces[i] != null and i < _dice_views.size():
			_dice_views[i].set_face(faces[i], values[i])


func _get_roll_face_candidates() -> Array:
	var candidates_by_die: Array = []
	for i in _dice_views.size():
		var resource := _round.get_dice_resource(i)
		if resource != null and resource.has_method("get_faces"):
			candidates_by_die.append(resource.get_faces())
		else:
			candidates_by_die.append([])
	return candidates_by_die


func _play_dice_face_effects(faces: Array[Resource], values: Array[int]) -> void:
	for i in faces.size():
		if i >= _dice_views.size() or i >= values.size():
			continue
		var face := faces[i]
		if face == null or not face.has_method("has_visual_effect") or not face.has_visual_effect():
			continue
		await face.play_visual_effect(
			_dice_views[i],
			{"faces": faces, "resolved_value": values[i], "dice_index": i}
		)


func _on_next_floor_pressed() -> void:
	if not _round.can_advance_floor() or not RunManager.can_advance_floor():
		return
	if RunManager.run_finished:
		return
	_open_shop()


func _open_shop() -> void:
	_selected_owned_index = -1
	RunManager.enter_shop()
	GameFlow.show_shop()


func _on_roster_changed() -> void:
	_refresh_board()
	_refresh_tray()
	_prepare_round_dice()


func _on_round_reset() -> void:
	_is_animating_target_progress = false
	if _target_progress_tween != null:
		_target_progress_tween.kill()
	_selected_owned_index = -1
	_dice_row.visible = true
	_refresh_board()
	_refresh_tray()
	_prepare_round_dice()
	_left_value.text = "0"
	_right_value.text = "0"
	_left_value.scale = Vector2.ONE
	_score_presenter.clear_active_hands()
	_active_hands_presenter.clear()
	_sync_ui()


func _on_round_phase_changed(_phase: RoundPhase.Phase) -> void:
	_sync_ui()


func _on_floor_changed(floor: int, target: int) -> void:
	_floor_label.text = "층: %d" % floor
	_target_label.text = "목표: %d" % target
	_sync_ui()


func _on_score_changed(score: int) -> void:
	_current_label.text = "점수: %d" % score
	_sync_ui()


func _on_chips_changed(_chips: int) -> void:
	_sync_ui()


func _on_gold_changed(amount: int) -> void:
	_gold_label.text = _format_currency_label(amount, RunManager.chips, RunManager.luck)
	_sync_ui()


func _format_currency_label(gold: int, chips: int, luck: float) -> String:
	return "골드: %d · 칩: %d · 행운: %d" % [gold, chips, int(round(luck))]


func _on_run_completed() -> void:
	_sync_ui()


func _sync_ui() -> void:
	_floor_label.text = "층: %d" % RunManager.current_floor
	_target_label.text = "목표: %d" % RunManager.target_score
	_current_label.text = "점수: %d" % RunManager.current_score
	_gold_label.text = _format_currency_label(RunManager.gold, RunManager.chips, RunManager.luck)
	if not _is_animating_target_progress:
		_update_target_progress()
	if _roll_lever.has_method("set_disabled"):
		_roll_lever.set_disabled(
			RunManager.run_finished
			or RunManager.get_placed_count() == 0
			or (not _round.can_roll() and not _lever_loop_running)
		)
	_next_floor_button.disabled = (
		not _round.can_advance_floor()
		or not RunManager.can_advance_floor()
		or RunManager.run_finished
	)
	_update_status()


func _update_target_progress() -> void:
	var segments := _build_target_progress_segments(RunManager.current_score)
	if segments.is_empty():
		_apply_target_progress_segment(0, maxi(RunManager.target_score, 1), 0)
		return

	var last_segment: Dictionary = segments.back()
	_apply_target_progress_segment(
		int(last_segment["color_index"]),
		int(last_segment["max_value"]),
		int(last_segment["value"]),
	)


func _animate_target_progress(from_score: int, to_score: int) -> void:
	if _target_progress_tween != null:
		_target_progress_tween.kill()

	if to_score <= from_score:
		_update_target_progress()
		return

	var segments := _build_target_progress_segments(to_score)
	var start_segment := _build_target_progress_segment(from_score)
	if start_segment.is_empty():
		_apply_target_progress_segment(0, maxi(RunManager.target_score, 1), 0)
	else:
		_apply_target_progress_segment(
			int(start_segment["color_index"]),
			int(start_segment["max_value"]),
			int(start_segment["value"]),
		)

	for i in segments.size():
		var segment: Dictionary = segments[i]
		var color_index := int(segment["color_index"])
		var max_value := int(segment["max_value"])
		var lower := int(segment["lower"])
		var upper := int(segment["upper"])
		var start_value := clampi(from_score - lower, 0, max_value)
		var end_value := clampi(to_score - lower, 0, max_value)
		if end_value <= start_value:
			continue

		_apply_target_progress_segment(color_index, max_value, start_value)
		_target_progress_tween = create_tween()
		_target_progress_tween.set_trans(Tween.TRANS_CUBIC)
		_target_progress_tween.set_ease(Tween.EASE_OUT)
		var fill_ratio := clampf(float(end_value - start_value) / float(max_value), 0.0, 1.0)
		var duration := lerpf(
			TARGET_PROGRESS_PARTIAL_MIN_DURATION,
			TARGET_PROGRESS_FULL_DURATION,
			fill_ratio
		) / maxf(_lever_speed_multiplier, 1.0)
		_target_progress_tween.tween_method(
			Callable(self, "_set_target_progress_value"),
			float(start_value),
			float(end_value),
			duration
		)
		await _target_progress_tween.finished

		if from_score < upper and to_score >= upper:
			_show_target_reward_float(color_index + 1)

		if end_value >= max_value and i < segments.size() - 1:
			await get_tree().create_timer(
				TARGET_PROGRESS_SEGMENT_PAUSE / maxf(_lever_speed_multiplier, 1.0)
			).timeout


func _build_target_progress_segments(score: int) -> Array[Dictionary]:
	var target := maxi(RunManager.target_score, 1)
	if score <= 0:
		return []

	var segments: Array[Dictionary] = []
	var lower := 0
	var upper := target
	var color_index := 0
	while lower < score and segments.size() < TARGET_PROGRESS_MAX_SEGMENTS:
		var segment_max := maxi(upper - lower, 1)
		var segment_value := clampi(score - lower, 0, segment_max)
		segments.append({
			"color_index": color_index,
			"lower": lower,
			"upper": upper,
			"max_value": segment_max,
			"value": segment_value,
		})

		lower = upper
		upper = int(round(float(upper) * GoldCalculator.DEFAULT_THRESHOLD_RATIO))
		if upper <= lower:
			upper = lower + target
		color_index += 1

	return segments


func _build_target_progress_segment(score: int) -> Dictionary:
	var target := maxi(RunManager.target_score, 1)
	var lower := 0
	var upper := target
	var color_index := 0
	var clamped_score := maxi(score, 0)
	while color_index < TARGET_PROGRESS_MAX_SEGMENTS:
		var segment_max := maxi(upper - lower, 1)
		var segment_value := clampi(clamped_score - lower, 0, segment_max)
		if clamped_score <= upper or color_index == TARGET_PROGRESS_MAX_SEGMENTS - 1:
			return {
				"color_index": color_index,
				"lower": lower,
				"upper": upper,
				"max_value": segment_max,
				"value": segment_value,
			}

		lower = upper
		upper = int(round(float(upper) * GoldCalculator.DEFAULT_THRESHOLD_RATIO))
		if upper <= lower:
			upper = lower + target
		color_index += 1
	return {}


func _apply_target_progress_segment(color_index: int, max_value: int, value: int) -> void:
	_target_progress_bar.max_value = float(maxi(max_value, 1))
	_set_target_progress_value(float(value))
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = TARGET_PROGRESS_COLORS[color_index % TARGET_PROGRESS_COLORS.size()]
	fill_style.corner_radius_top_left = 6
	fill_style.corner_radius_top_right = 6
	fill_style.corner_radius_bottom_right = 6
	fill_style.corner_radius_bottom_left = 6
	_target_progress_bar.add_theme_stylebox_override("fill", fill_style)


func _set_target_progress_value(value: float) -> void:
	_target_progress_bar.value = clampf(value, 0.0, _target_progress_bar.max_value)
	_target_progress_value_label.text = "%d/%d" % [
		int(round(_target_progress_bar.value)),
		int(round(_target_progress_bar.max_value)),
	]


func _show_target_reward_float(reward_amount: int) -> void:
	var reward_label := Label.new()
	reward_label.text = "+%d 골드" % reward_amount
	reward_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	reward_label.custom_minimum_size = Vector2(96, 28)
	reward_label.size = reward_label.custom_minimum_size
	reward_label.pivot_offset = reward_label.size * 0.5
	reward_label.add_theme_font_size_override("font_size", 22)
	reward_label.add_theme_color_override("font_color", Color(0.98, 0.72, 0.18, 1.0))
	reward_label.add_theme_color_override("font_outline_color", Color(0.18, 0.12, 0.04, 1.0))
	reward_label.add_theme_constant_override("outline_size", 4)
	add_child(reward_label)

	var start_position := (
		_target_progress_bar.global_position
		+ Vector2((_target_progress_bar.size.x - reward_label.size.x) * 0.5, -32.0)
	)
	reward_label.global_position = start_position
	reward_label.modulate = Color(1, 1, 1, 0)
	reward_label.scale = Vector2(0.92, 0.92)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(reward_label, "global_position", start_position + Vector2(0, -34), TARGET_REWARD_FLOAT_DURATION)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(reward_label, "scale", Vector2(1.08, 1.08), 0.16)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(reward_label, "modulate:a", 1.0, 0.12)
	tween.tween_property(reward_label, "modulate:a", 0.0, 0.2)\
		.set_delay(TARGET_REWARD_FLOAT_DURATION - 0.2)
	tween.finished.connect(reward_label.queue_free)


func _is_lever_stopped() -> bool:
	return _lever_speed_multiplier <= 0.0


func _update_status() -> void:
	if RunManager.run_finished:
		_status_label.text = "5층 클리어! v0.1 완료"
		return

	if RunManager.get_placed_count() == 0:
		_status_label.text = "보유 주사위를 보드 칸에 배치한 뒤 레버를 당기세요."
		return

	match _round.phase:
		RoundPhase.Phase.IDLE:
			_status_label.text = "레버를 아래로 당기면 칩을 하나씩 써서 배치한 주사위를 굴립니다."
		RoundPhase.Phase.ROLLING:
			_status_label.text = "주사위를 굴리는 중..."
		RoundPhase.Phase.SCORING:
			_status_label.text = "점수를 계산하는 중..."
		RoundPhase.Phase.REROLL_READY:
			if RunManager.can_advance_floor():
				_status_label.text = "목표 달성! 더 굴리거나 Next Floor(상점)로 이동하세요."
			elif RunManager.chips > 0:
				_status_label.text = "레버를 당기면 남은 칩으로 계속 굴립니다. 배치를 바꿔도 됩니다."
			else:
				_status_label.text = "칩을 모두 썼습니다. 배치를 조정해 보세요."
