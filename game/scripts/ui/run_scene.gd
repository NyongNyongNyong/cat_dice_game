extends Control

const DICE_SCENE := preload("res://scenes/dice/dice.tscn")
const DICE_SLOT_SCENE := preload("res://scenes/ui/dice_slot.tscn")
const GoldCalculator := preload("res://scripts/core/gold_calculator.gd")
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
const FACE_PREVIEW_HOVER_DELAY := 0.32

@onready var _floor_label: Label = %FloorLabel
@onready var _gold_label: Label = %GoldLabel
@onready var _target_label: Label = %TargetScoreLabel
@onready var _current_label: Label = %CurrentScoreLabel
@onready var _target_progress_bar: ProgressBar = %TargetProgressBar
@onready var _target_progress_value_label: Label = %ProgressValueLabel
@onready var _status_label: Label = %StatusLabel
@onready var _dice_row: Control = %DiceRow
@onready var _dice_container: HBoxContainer = %DiceContainer
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

var _dice_views: Array[Control] = []
var _dice_slots: Array = []
var _hovered_dice_index := -1
var _face_preview_request_id := 0
var _position_swap_source_index := -1
var _score_after_reroll := false
var _lever_speed_multiplier := 0.0
var _lever_loop_running := false
var _is_animating_target_progress := false
var _target_progress_tween: Tween
var _roll_slot: Control


func _ready() -> void:
	_setup_round_flow()
	if not RunManager.is_run_started():
		RunManager.start_run()
	_apply_roster_to_round()
	_spawn_dice()
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
	_score_presenter.set_dice_views(_dice_views)
	_roll_presenter.set_dice_views(_dice_views)
	_reroll_preview_presenter.setup(_dice_popup_layer)

	_round.phase_changed.connect(_on_round_phase_changed)
	_round.dice_rolled.connect(_on_dice_rolled)
	_round.die_selected.connect(_on_die_selected)
	_round.die_rerolled.connect(_on_die_rerolled)
	_round.score_ready.connect(_on_score_ready)
	_round.round_reset.connect(_on_round_reset)

	RunManager.floor_changed.connect(_on_floor_changed)
	RunManager.score_changed.connect(_on_score_changed)
	RunManager.chips_changed.connect(_on_chips_changed)
	RunManager.gold_changed.connect(_on_gold_changed)
	RunManager.run_completed.connect(_on_run_completed)
	RunManager.roster_changed.connect(_on_roster_changed)

	_roll_lever.speed_changed.connect(_on_roll_lever_speed_changed)
	_next_floor_button.pressed.connect(_on_next_floor_pressed)


func _apply_roster_to_round() -> void:
	_round.dice_loadout = null
	_round.dice_resources = RunManager.get_owned_dice()


func _spawn_dice() -> void:
	for child in _dice_container.get_children():
		child.queue_free()
	_dice_views.clear()
	_dice_slots.clear()

	var dice_count := _round.get_dice_count()
	for i in dice_count:
		var slot = DICE_SLOT_SCENE.instantiate()
		slot.set_slot_index(i)
		_dice_container.add_child(slot)
		slot.mouse_entered.connect(_on_dice_mouse_entered.bind(i))
		slot.mouse_exited.connect(_on_dice_mouse_exited)
		slot.clicked.connect(_on_dice_slot_clicked)
		slot.drag_started.connect(_on_dice_slot_drag_started)
		slot.drop_requested.connect(_on_dice_slot_drop_requested)
		_dice_slots.append(slot)

		var dice: Control = DICE_SCENE.instantiate()
		slot.set_dice_view(dice)
		dice.show_placeholder()
		_dice_views.append(dice)

	_show_roster_previews()
	_score_presenter.set_dice_views(_dice_views)
	_roll_presenter.set_dice_views(_dice_views)


func _show_roster_previews() -> void:
	for i in _dice_views.size():
		var resource := _round.get_dice_resource(i)
		if resource == null:
			_dice_views[i].show_placeholder()
			continue
		var preview_face: Resource = resource.get_roster_preview_face()
		if preview_face == null:
			_dice_views[i].show_placeholder()
			continue
		var preview_value: int = resource.get_roster_preview_value()
		_dice_views[i].set_face(preview_face, preview_value)


func _on_roll_lever_speed_changed(multiplier: float) -> void:
	if RunManager.run_finished:
		return
	_lever_speed_multiplier = multiplier
	_apply_lever_speed()
	if _lever_speed_multiplier > 0.0:
		_set_position_swap_source(-1)
		_run_lever_loop()
	_sync_ui()


func _run_lever_loop() -> void:
	if _lever_loop_running:
		return
	_lever_loop_running = true

	while _lever_speed_multiplier > 0.0 and _round.can_roll() and not RunManager.run_finished:
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
	_reroll_preview_presenter.set_active(false)
	_reroll_preview_presenter.hide_preview()
	await _roll_presenter.play_roll(_round.dice_faces, values, _get_roll_face_candidates())
	await _play_dice_face_effects(_round.dice_faces, values)
	_round.complete_roll_presentation()


func _on_die_rerolled(values: Array[int]) -> void:
	_score_after_reroll = true
	_reroll_preview_presenter.set_active(false)
	_reroll_preview_presenter.hide_preview()
	_clear_dice_selection()
	await _roll_presenter.play_reroll(
		_round.last_rerolled_die_index,
		_round.dice_faces,
		values,
		_get_roll_face_candidates()
	)
	await _play_dice_face_effects(_round.dice_faces, values)


func _on_score_ready(evaluation: HandEvaluation) -> void:
	_reroll_preview_presenter.set_active(false)
	_reroll_preview_presenter.hide_preview()
	var hands_only := _score_after_reroll
	_score_after_reroll = false
	var rerolled_index := _round.last_rerolled_die_index if hands_only else -1
	await _score_presenter.play(evaluation, hands_only, rerolled_index, _round.dice_faces)
	_is_animating_target_progress = true
	var previous_score := RunManager.current_score
	RunManager.add_score(evaluation.total_score)
	if _active_hands_presenter.has_method("add_roll"):
		_active_hands_presenter.add_roll(evaluation)
	await _animate_target_progress(previous_score, RunManager.current_score)
	_is_animating_target_progress = false
	_round.complete_score_presentation()
	_show_dice_faces(_round.dice_faces, evaluation.dice_values)
	_clear_dice_selection()
	_reroll_preview_presenter.set_active(_can_hover_dice_faces())
	_sync_ui()


func _on_die_selected(index: int) -> void:
	_update_dice_selection(index)
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


func _update_dice_selection(index: int) -> void:
	for i in _dice_views.size():
		_dice_views[i].set_selected(i == index)
	for i in _dice_slots.size():
		_dice_slots[i].set_selected(i == index)


func _clear_dice_selection() -> void:
	for dice in _dice_views:
		dice.clear_selection()
	for slot in _dice_slots:
		slot.set_selected(false)


func _set_position_swap_source(index: int) -> void:
	_position_swap_source_index = index
	if _position_swap_source_index < 0:
		_clear_dice_selection()
		return
	_update_dice_selection(_position_swap_source_index)


func _can_reposition_dice() -> bool:
	return (
		not RunManager.run_finished
		and _round.phase == RoundPhase.Phase.IDLE
		and _is_lever_stopped()
	)


func _handle_position_click(index: int) -> void:
	if not _can_reposition_dice():
		return
	if index < 0 or index >= _dice_views.size():
		return

	if _position_swap_source_index < 0:
		_set_position_swap_source(index)
		return
	if _position_swap_source_index == index:
		_set_position_swap_source(-1)
		return

	var source_index := _position_swap_source_index
	_set_position_swap_source(-1)
	if RunManager.swap_owned_dice(source_index, index):
		_sync_ui()


func _on_dice_slot_clicked(index: int) -> void:
	if _can_reposition_dice():
		_handle_position_click(index)
		return
	if not _round.can_reroll_preview():
		return
	_round.select_die(index)


func _on_dice_slot_drag_started(index: int) -> void:
	_face_preview_request_id += 1
	_reroll_preview_presenter.hide_preview()
	if _can_reposition_dice():
		_set_position_swap_source(index)


func _on_dice_slot_drop_requested(from_index: int, to_index: int) -> void:
	if not _can_reposition_dice():
		return
	if from_index < 0 or from_index >= _dice_views.size():
		return
	if to_index < 0 or to_index >= _dice_views.size():
		return

	_set_position_swap_source(-1)
	if RunManager.swap_owned_dice(from_index, to_index):
		_sync_ui()


func _on_dice_mouse_entered(index: int) -> void:
	_hovered_dice_index = index
	_face_preview_request_id += 1
	var request_id := _face_preview_request_id
	await get_tree().create_timer(FACE_PREVIEW_HOVER_DELAY).timeout
	if request_id != _face_preview_request_id:
		return
	if _hovered_dice_index != index:
		return
	if not _can_hover_dice_faces():
		return
	var resource := _round.get_dice_resource(index)
	if resource == null:
		return
	_reroll_preview_presenter.show_die_faces(
		_dice_views[index],
		resource.get_faces(),
		_get_face_hover_context(index),
		index,
	)


func _on_dice_mouse_exited() -> void:
	_hovered_dice_index = -1
	_face_preview_request_id += 1
	_reroll_preview_presenter.hide_preview()


func _on_next_floor_pressed() -> void:
	if not _round.can_advance_floor() or not RunManager.can_advance_floor():
		return
	if RunManager.run_finished:
		return

	_open_shop()


func _open_shop() -> void:
	_reroll_preview_presenter.set_active(false)
	_reroll_preview_presenter.hide_preview()
	_position_swap_source_index = -1
	_clear_dice_selection()
	RunManager.enter_shop()
	GameFlow.show_shop()


func _on_roster_changed() -> void:
	_apply_roster_to_round()
	if _position_swap_source_index >= _dice_views.size():
		_set_position_swap_source(-1)
	_show_roster_previews()


func _on_round_reset() -> void:
	_score_after_reroll = false
	_position_swap_source_index = -1
	_is_animating_target_progress = false
	if _target_progress_tween != null:
		_target_progress_tween.kill()
	_reroll_preview_presenter.set_active(false)
	_reroll_preview_presenter.hide_preview()
	_clear_dice_selection()
	_dice_row.visible = true
	_show_roster_previews()
	_left_value.text = "0"
	_right_value.text = "0"
	_left_value.scale = Vector2.ONE
	_score_presenter.clear_active_hands()
	_active_hands_presenter.clear()
	_sync_ui()


func _on_round_phase_changed(_phase: RoundPhase.Phase) -> void:
	if not _can_reposition_dice():
		_set_position_swap_source(-1)
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
	_gold_label.text = "골드: %d · 칩: %d" % [amount, RunManager.chips]
	_sync_ui()


func _on_run_completed() -> void:
	_sync_ui()


func _sync_ui() -> void:
	_floor_label.text = "층: %d" % RunManager.current_floor
	_target_label.text = "목표: %d" % RunManager.target_score
	_current_label.text = "점수: %d" % RunManager.current_score
	_gold_label.text = "골드: %d · 칩: %d" % [RunManager.gold, RunManager.chips]
	if not _is_animating_target_progress:
		_update_target_progress()
	if _roll_lever.has_method("set_disabled"):
		_roll_lever.set_disabled(
			RunManager.run_finished or (not _round.can_roll() and not _lever_loop_running)
		)
	for slot in _dice_slots:
		if slot.has_method("set_drag_enabled"):
			slot.set_drag_enabled(_can_reposition_dice())
	_next_floor_button.disabled = (
		not _round.can_advance_floor()
		or not RunManager.can_advance_floor()
		or RunManager.run_finished
	)
	_reroll_preview_presenter.set_active(_can_hover_dice_faces())
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
	# TODO: Add a stronger over-target burst when a full extra segment completes.


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


func _can_hover_dice_faces() -> bool:
	if RunManager.run_finished:
		return false
	match _round.phase:
		RoundPhase.Phase.IDLE, RoundPhase.Phase.REROLL_READY:
			return true
		_:
			return false


func _is_lever_stopped() -> bool:
	return _lever_speed_multiplier <= 0.0


func _get_face_hover_context(index: int) -> Array[Resource]:
	if not _round.dice_faces.is_empty() and index < _round.dice_faces.size():
		return _round.dice_faces
	var resource := _round.get_dice_resource(index)
	if resource == null:
		return []
	return resource.get_faces()


func _update_status() -> void:
	if RunManager.run_finished:
		_status_label.text = "5층 클리어! v0.1 완료"
		return

	match _round.phase:
		RoundPhase.Phase.IDLE:
			_status_label.text = "레버를 아래로 당기면 칩을 하나씩 써서 계속 굴립니다."
		RoundPhase.Phase.ROLLING:
			_status_label.text = "주사위를 굴리는 중..."
		RoundPhase.Phase.SCORING:
			_status_label.text = "점수를 계산하는 중..."
		RoundPhase.Phase.REROLL_READY:
			if RunManager.can_advance_floor():
				_status_label.text = "목표 달성! 더 굴리거나 Next Floor(상점)로 이동하세요."
			elif RunManager.chips > 0:
				_status_label.text = "레버를 아래로 당기면 남은 칩으로 계속 굴립니다."
			else:
				_status_label.text = (
					"칩을 모두 썼습니다. 목표에 못 미쳤다면 다음 구조 조정이 필요합니다."
				)
