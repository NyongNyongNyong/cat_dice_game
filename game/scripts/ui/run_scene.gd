extends Control

const DICE_SCENE := preload("res://scenes/dice/dice.tscn")

@onready var _floor_label: Label = $MarginContainer/VBox/Header/FloorLabel
@onready var _gold_label: Label = $MarginContainer/VBox/Header/GoldLabel
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
@onready var _shop_panel: PanelContainer = $MarginContainer/VBox/ShopPanel
@onready var _shop_offer_name: Label = (
	$MarginContainer/VBox/ShopPanel/ShopVBox/ShopOfferPanel/ShopOfferVBox/ShopOfferName
)
@onready var _shop_slots: VBoxContainer = $MarginContainer/VBox/ShopPanel/ShopVBox/ShopSlots
@onready var _shop_continue_button: Button = $MarginContainer/VBox/ShopPanel/ShopVBox/ShopContinueButton
@onready var _dice_popup_layer: Control = $MarginContainer/VBox/DiceRow/PopupOverlay
@onready var _round: RoundController = $RoundController
@onready var _roll_presenter: RollPhasePresenter = $RollPhasePresenter
@onready var _score_presenter: ScorePhasePresenter = $ScorePhasePresenter
@onready var _reroll_preview_presenter: Node = $RerollPreviewPresenter
@onready var _shop_presenter: Node = $DiceShopPresenter

var _dice_views: Array[Control] = []
var _hovered_dice_index := -1
var _score_after_reroll := false
var _last_round_gold_earned := 0


func _ready() -> void:
	_setup_round_flow()
	RunManager.start_run()
	_apply_roster_to_round()
	_spawn_dice()
	_round.begin_round()
	_sync_ui()


func _setup_round_flow() -> void:
	_roll_presenter.setup(_roll_slot, _dice_row)
	_score_presenter.setup(_dice_row, _popup_overlay, _left_value, _right_value, _status_label)
	_score_presenter.set_dice_views(_dice_views)
	_reroll_preview_presenter.setup(_dice_popup_layer)
	_shop_presenter.setup(_shop_panel, _shop_offer_name, _shop_slots, _shop_continue_button)

	_round.phase_changed.connect(_on_round_phase_changed)
	_round.dice_rolled.connect(_on_dice_rolled)
	_round.die_selected.connect(_on_die_selected)
	_round.die_rerolled.connect(_on_die_rerolled)
	_round.score_ready.connect(_on_score_ready)
	_round.round_reset.connect(_on_round_reset)

	RunManager.floor_changed.connect(_on_floor_changed)
	RunManager.score_changed.connect(_on_score_changed)
	RunManager.gold_changed.connect(_on_gold_changed)
	RunManager.run_completed.connect(_on_run_completed)
	RunManager.roster_changed.connect(_on_roster_changed)

	_roll_button.pressed.connect(_on_roll_pressed)
	_next_floor_button.pressed.connect(_on_next_floor_pressed)
	_shop_presenter.continue_pressed.connect(_on_shop_continue_pressed)
	_shop_presenter.replace_requested.connect(_on_shop_replace_requested)


func _apply_roster_to_round() -> void:
	_round.dice_loadout = null
	_round.dice_resources = RunManager.get_owned_dice()


func _spawn_dice() -> void:
	for child in _dice_container.get_children():
		child.queue_free()
	_dice_views.clear()

	var dice_count := _round.get_dice_count()
	for i in dice_count:
		var dice: Control = DICE_SCENE.instantiate()
		_dice_container.add_child(dice)
		dice.show_placeholder()
		dice.mouse_entered.connect(_on_dice_mouse_entered.bind(i))
		dice.mouse_exited.connect(_on_dice_mouse_exited)
		dice.gui_input.connect(_on_dice_gui_input.bind(i))
		_dice_views.append(dice)

	_score_presenter.set_dice_views(_dice_views)


func _on_roll_pressed() -> void:
	if _is_shop_open() or not _round.can_roll() or RunManager.run_finished:
		return
	_round.roll()


func _on_dice_rolled(values: Array[int]) -> void:
	_reroll_preview_presenter.set_active(false)
	_reroll_preview_presenter.hide_preview()
	await _roll_presenter.play(values)
	_show_dice_faces(_round.dice_faces, values)
	await _play_dice_face_effects(_round.dice_faces, values)
	_round.complete_roll_presentation()


func _on_die_rerolled(values: Array[int]) -> void:
	_score_after_reroll = true
	_reroll_preview_presenter.set_active(false)
	_reroll_preview_presenter.hide_preview()
	_clear_dice_selection()
	_show_dice_faces(_round.dice_faces, values)
	await _play_dice_face_effects(_round.dice_faces, values)
	_reroll_preview_presenter.invalidate_cache()


func _on_score_ready(evaluation: HandEvaluation) -> void:
	_reroll_preview_presenter.set_active(false)
	_reroll_preview_presenter.hide_preview()
	var hands_only := _score_after_reroll
	_score_after_reroll = false
	var rerolled_index := _round.last_rerolled_die_index if hands_only else -1
	await _score_presenter.play(evaluation, hands_only, rerolled_index, _round.dice_faces)
	_round.complete_score_presentation()
	RunManager.set_score(evaluation.total_score)
	_show_dice_faces(_round.dice_faces, evaluation.dice_values)
	_clear_dice_selection()
	_reroll_preview_presenter.set_active(_round.can_reroll_preview() and not _is_shop_open())
	_sync_ui()


func _on_die_selected(index: int) -> void:
	if _is_shop_open():
		return
	_update_dice_selection(index)
	_sync_ui()


func _show_dice_faces(faces: Array, values: Array[int]) -> void:
	_dice_row.visible = true
	for i in values.size():
		if i < faces.size() and faces[i] != null and i < _dice_views.size():
			_dice_views[i].set_face(faces[i], values[i])


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


func _clear_dice_selection() -> void:
	for dice in _dice_views:
		dice.clear_selection()


func _on_dice_mouse_entered(index: int) -> void:
	if _is_shop_open():
		return
	_hovered_dice_index = index
	if not _round.can_reroll_preview():
		return
	_reroll_preview_presenter.show_preview_result(_dice_views[index], _round.get_reroll_preview(index))


func _on_dice_mouse_exited() -> void:
	_hovered_dice_index = -1
	_reroll_preview_presenter.hide_preview()


func _on_dice_gui_input(event: InputEvent, index: int) -> void:
	if _is_shop_open() or not _round.can_reroll_preview():
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
	if RunManager.run_finished:
		return

	_open_shop()


func _open_shop() -> void:
	_reroll_preview_presenter.set_active(false)
	_reroll_preview_presenter.hide_preview()
	_clear_dice_selection()
	_last_round_gold_earned = RunManager.collect_round_gold()
	_shop_presenter.open(
		RunManager.get_dice_roster(),
		RunManager.get_shop_replace_offer_id()
	)
	_sync_ui()


func _on_shop_replace_requested(slot_index: int) -> void:
	if RunManager.replace_owned_dice_at(slot_index, RunManager.get_shop_replace_offer_id()):
		_apply_roster_to_round()
		_shop_presenter.open(
			RunManager.get_dice_roster(),
			RunManager.get_shop_replace_offer_id()
		)
		_reroll_preview_presenter.invalidate_cache()
	_sync_ui()


func _on_shop_continue_pressed() -> void:
	_shop_presenter.close()
	RunManager.advance_floor()
	if RunManager.run_finished:
		_sync_ui()
		return

	_apply_roster_to_round()
	_spawn_dice()
	_round.begin_round()
	_sync_ui()


func _on_roster_changed() -> void:
	_apply_roster_to_round()
	_reroll_preview_presenter.invalidate_cache()


func _on_round_reset() -> void:
	_score_after_reroll = false
	_shop_presenter.close()
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
	_last_round_gold_earned = 0
	_sync_ui()


func _on_score_changed(score: int) -> void:
	_current_label.text = "칩: %d" % score
	_sync_ui()


func _on_gold_changed(amount: int) -> void:
	_gold_label.text = "골드: %d" % amount
	_sync_ui()


func _on_run_completed() -> void:
	_shop_presenter.close()
	_sync_ui()


func _is_shop_open() -> bool:
	return _shop_panel.visible


func _sync_ui() -> void:
	_floor_label.text = "층: %d" % RunManager.current_floor
	_target_label.text = "목표: %d" % RunManager.target_score
	_current_label.text = "칩: %d" % RunManager.current_score
	_gold_label.text = "골드: %d" % RunManager.gold
	var shop_open: bool = _is_shop_open()
	_roll_button.disabled = shop_open or not _round.can_roll() or RunManager.run_finished
	_next_floor_button.disabled = (
		shop_open
		or not _round.can_advance_floor()
		or not RunManager.can_advance_floor()
		or RunManager.run_finished
	)
	_shop_continue_button.disabled = RunManager.run_finished
	_update_status()


func _update_status() -> void:
	if RunManager.run_finished:
		_status_label.text = "5층 클리어! v0.1 완료"
		return

	if _is_shop_open():
		if _last_round_gold_earned > 0:
			_status_label.text = (
				"+%d 골드 획득! 상점에서 주사위를 교체한 뒤 다음 층으로 이동하세요." % _last_round_gold_earned
			)
		else:
			_status_label.text = "상점에서 주사위를 교체한 뒤 다음 층으로 이동하세요."
		return

	match _round.phase:
		RoundPhase.Phase.IDLE:
			_status_label.text = "Roll을 눌러 주사위를 굴리세요."
		RoundPhase.Phase.ROLLING:
			_status_label.text = "주사위를 굴리는 중..."
		RoundPhase.Phase.SCORING:
			_status_label.text = "칩을 계산하는 중..."
		RoundPhase.Phase.REROLL_READY:
			if _round.selected_die_index >= 0:
				if RunManager.has_met_chip_target() and not RunManager.can_afford_reroll():
					_status_label.text = "골드가 부족해 리롤할 수 없습니다. 선택을 해제하거나 Next Floor로 이동하세요."
				else:
					_status_label.text = "Roll을 눌러 선택한 주사위를 다시 굴리세요."
			elif RunManager.can_advance_floor():
				if RunManager.can_afford_reroll():
					_status_label.text = (
						"목표 달성! 리롤 1골드 — 더 높은 구간을 노리거나 Next Floor(상점)로 이동하세요."
					)
				else:
					_status_label.text = (
						"목표 달성! 골드가 부족해 리롤할 수 없습니다. Next Floor로 골드를 확보하세요."
					)
			else:
				_status_label.text = (
					"주사위에 마우스를 올려 리롤 효과를 확인하고, 클릭해 선택하세요."
				)
