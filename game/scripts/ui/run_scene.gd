extends Control

const DICE_SCENE := preload("res://scenes/dice/dice.tscn")

@onready var _floor_label: Label = $MarginContainer/VBox/Header/FloorLabel
@onready var _target_label: Label = $MarginContainer/VBox/Header/ScoreHeaderPanel/ScoreHeaderRow/TargetScoreLabel
@onready var _current_label: Label = $MarginContainer/VBox/Header/ScoreHeaderPanel/ScoreHeaderRow/CurrentScoreLabel
@onready var _status_label: Label = $MarginContainer/VBox/StatusLabel
@onready var _roll_slot: Control = $MarginContainer/VBox/RollPhaseSlot
@onready var _dice_row: Control = $MarginContainer/VBox/DiceRow
@onready var _dice_container: HBoxContainer = $MarginContainer/VBox/DiceRow/CenterContainer/DiceContainer
@onready var _popup_overlay: Control = $ScoreOverlay
@onready var _left_value: Label = $MarginContainer/VBox/ScoreBoard/LeftPanel/VBox/LeftValue
@onready var _right_value: Label = $MarginContainer/VBox/ScoreBoard/RightPanel/VBox/RightValue
@onready var _roll_button: Button = $MarginContainer/VBox/Buttons/RollButton
@onready var _next_floor_button: Button = $MarginContainer/VBox/Buttons/NextFloorButton
@onready var _dice_popup_layer: Control = $MarginContainer/VBox/DiceRow/PopupOverlay
@onready var _round: RoundController = $RoundController
@onready var _roll_presenter: RollPhasePresenter = $RollPhasePresenter
@onready var _score_presenter: ScorePhasePresenter = $ScorePhasePresenter
@onready var _reroll_preview_presenter: Node = $RerollPreviewPresenter

var _dice_views: Array[Control] = []
var _hovered_dice_index := -1


func _ready() -> void:
	_spawn_dice()
	_setup_round_flow()
	RunManager.start_run()
	_round.begin_round()
	_sync_ui()


func _setup_round_flow() -> void:
	_roll_presenter.setup(_roll_slot, _dice_row)
	_score_presenter.setup(_dice_row, _popup_overlay, _left_value, _right_value, _status_label)
	_score_presenter.set_dice_views(_dice_views)
	_reroll_preview_presenter.setup(_dice_popup_layer)

	_round.phase_changed.connect(_on_round_phase_changed)
	_round.dice_rolled.connect(_on_dice_rolled)
	_round.die_selected.connect(_on_die_selected)
	_round.die_rerolled.connect(_on_die_rerolled)
	_round.score_ready.connect(_on_score_ready)
	_round.round_reset.connect(_on_round_reset)

	RunManager.floor_changed.connect(_on_floor_changed)
	RunManager.score_changed.connect(_on_score_changed)
	RunManager.run_completed.connect(_on_run_completed)

	_roll_button.pressed.connect(_on_roll_pressed)
	_next_floor_button.pressed.connect(_on_next_floor_pressed)


func _spawn_dice() -> void:
	for child in _dice_container.get_children():
		child.queue_free()
	_dice_views.clear()

	for i in RunManager.DICE_COUNT:
		var dice: Control = DICE_SCENE.instantiate()
		_dice_container.add_child(dice)
		dice.show_placeholder()
		dice.mouse_entered.connect(_on_dice_mouse_entered.bind(i))
		dice.mouse_exited.connect(_on_dice_mouse_exited)
		dice.gui_input.connect(_on_dice_gui_input.bind(i))
		_dice_views.append(dice)

	_score_presenter.set_dice_views(_dice_views)


func _on_roll_pressed() -> void:
	if not _round.can_roll() or RunManager.run_finished:
		return
	_round.roll()


func _on_dice_rolled(values: Array[int]) -> void:
	_reroll_preview_presenter.set_active(false)
	_reroll_preview_presenter.hide_preview()
	await _roll_presenter.play(values)
	_round.complete_roll_presentation()
	_show_dice_values(values)


func _on_die_rerolled(values: Array[int]) -> void:
	_reroll_preview_presenter.set_active(false)
	_reroll_preview_presenter.hide_preview()
	_clear_dice_selection()
	_show_dice_values(values)
	_reroll_preview_presenter.invalidate_cache()


func _on_score_ready(evaluation: HandEvaluation) -> void:
	_reroll_preview_presenter.set_active(false)
	_reroll_preview_presenter.hide_preview()
	await _score_presenter.play(evaluation)
	_round.complete_score_presentation()
	RunManager.set_score(evaluation.total_score)
	_show_dice_values(evaluation.dice_values)
	_clear_dice_selection()
	_reroll_preview_presenter.set_active(_round.can_reroll_preview())
	_sync_ui()


func _on_die_selected(index: int) -> void:
	_update_dice_selection(index)
	_sync_ui()


func _show_dice_values(values: Array[int]) -> void:
	_dice_row.visible = true
	for i in values.size():
		_dice_views[i].set_value(values[i])


func _update_dice_selection(index: int) -> void:
	for i in _dice_views.size():
		_dice_views[i].set_selected(i == index)


func _clear_dice_selection() -> void:
	for dice in _dice_views:
		dice.clear_selection()


func _on_dice_mouse_entered(index: int) -> void:
	_hovered_dice_index = index
	if not _round.can_reroll_preview():
		return
	_reroll_preview_presenter.show_preview(_dice_views[index], index, _round.dice_values)


func _on_dice_mouse_exited() -> void:
	_hovered_dice_index = -1
	_reroll_preview_presenter.hide_preview()


func _on_dice_gui_input(event: InputEvent, index: int) -> void:
	if not _round.can_reroll_preview():
		return
	if not event is InputEventMouseButton:
		return
	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return

	_round.select_die(index)


func _on_next_floor_pressed() -> void:
	if not _round.can_advance_floor() or not RunManager.can_advance_floor():
		return

	RunManager.advance_floor()
	if RunManager.run_finished:
		return

	_round.begin_round()
	_sync_ui()


func _on_round_reset() -> void:
	_reroll_preview_presenter.set_active(false)
	_reroll_preview_presenter.hide_preview()
	_roll_slot.visible = false
	_dice_row.visible = true
	for dice in _dice_views:
		dice.show_placeholder()
	_left_value.text = "0"
	_right_value.text = "0"
	_left_value.scale = Vector2.ONE
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


func _on_run_completed() -> void:
	_sync_ui()


func _sync_ui() -> void:
	_roll_button.disabled = not _round.can_roll() or RunManager.run_finished
	_next_floor_button.disabled = (
		not _round.can_advance_floor()
		or not RunManager.can_advance_floor()
		or RunManager.run_finished
	)
	_update_status()


func _update_status() -> void:
	if RunManager.run_finished:
		_status_label.text = "5층 클리어! v0.1 완료"
		return

	match _round.phase:
		RoundPhase.Phase.IDLE:
			_status_label.text = "Roll을 눌러 주사위를 굴리세요."
		RoundPhase.Phase.ROLLING:
			_status_label.text = "주사위를 굴리는 중..."
		RoundPhase.Phase.SCORING:
			_status_label.text = "점수를 계산하는 중..."
		RoundPhase.Phase.REROLL_READY:
			if _round.selected_die_index >= 0:
				_status_label.text = "Roll을 눌러 선택한 주사위를 다시 굴리세요."
			elif RunManager.can_advance_floor():
				_status_label.text = (
					"목표 달성! Next Floor로 이동하거나, 주사위를 선택해 더 리롤할 수 있습니다."
				)
			else:
				_status_label.text = (
					"주사위에 마우스를 올려 리롤 효과를 확인하고, 클릭해 선택하세요."
				)
