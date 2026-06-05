extends Control

const DICE_SCENE := preload("res://scenes/dice/dice.tscn")

@onready var _floor_label: Label = $MarginContainer/VBox/Header/FloorLabel
@onready var _target_label: Label = $MarginContainer/VBox/Header/TargetScoreLabel
@onready var _current_label: Label = $MarginContainer/VBox/Header/CurrentScoreLabel
@onready var _status_label: Label = $MarginContainer/VBox/StatusLabel
@onready var _roll_slot: Control = $MarginContainer/VBox/RollPhaseSlot
@onready var _dice_row: Control = $MarginContainer/VBox/DiceRow
@onready var _dice_container: HBoxContainer = $MarginContainer/VBox/DiceRow/CenterContainer/DiceContainer
@onready var _popup_overlay: Control = $MarginContainer/VBox/DiceRow/PopupOverlay
@onready var _left_value: Label = $MarginContainer/VBox/ScoreBoard/LeftPanel/VBox/LeftValue
@onready var _right_value: Label = $MarginContainer/VBox/ScoreBoard/RightPanel/VBox/RightValue
@onready var _roll_button: Button = $MarginContainer/VBox/Buttons/RollButton
@onready var _next_floor_button: Button = $MarginContainer/VBox/Buttons/NextFloorButton
@onready var _round: RoundController = $RoundController
@onready var _roll_presenter: RollPhasePresenter = $RollPhasePresenter
@onready var _score_presenter: ScorePhasePresenter = $ScorePhasePresenter

var _dice_views: Array[Control] = []


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

	_round.phase_changed.connect(_on_round_phase_changed)
	_round.dice_rolled.connect(_on_dice_rolled)
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
		_dice_views.append(dice)

	_score_presenter.set_dice_views(_dice_views)


func _on_roll_pressed() -> void:
	if not _round.can_roll() or RunManager.run_finished:
		return
	_round.roll()


func _on_dice_rolled(values: Array[int]) -> void:
	await _roll_presenter.play(values)
	_round.complete_roll_presentation()


func _on_score_ready(evaluation: HandEvaluation) -> void:
	await _score_presenter.play(evaluation)
	_round.complete_score_presentation()
	RunManager.set_score(evaluation.total_score)
	_sync_ui()


func _on_next_floor_pressed() -> void:
	if not _round.can_advance_floor() or not RunManager.can_advance_floor():
		return

	RunManager.advance_floor()
	if RunManager.run_finished:
		return

	_round.begin_round()
	_sync_ui()


func _on_round_reset() -> void:
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
		RoundPhase.Phase.RESOLVED:
			if RunManager.can_advance_floor():
				_status_label.text = "목표 달성! Next Floor로 이동하세요."
			else:
				_status_label.text = "목표 점수에 미달했습니다. (v0.1에서는 재시도 없음)"
