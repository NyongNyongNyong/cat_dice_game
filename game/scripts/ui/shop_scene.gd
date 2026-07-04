extends Control

@onready var _floor_label: Label = %FloorLabel
@onready var _gold_label: Label = %GoldLabel
@onready var _status_label: Label = %StatusLabel
@onready var _shop_dice_row: HBoxContainer = %ShopDiceRow
@onready var _pool_grid: GridContainer = %PoolGrid
@onready var _pending_label: Label = %PendingLabel
@onready var _confirm_button: Button = %ConfirmButton
@onready var _continue_button: Button = %ContinueButton
@onready var _popup_overlay: Control = %PopupOverlay
@onready var _shop_presenter: Node = %DiceShopPresenter
@onready var _hover_presenter: Node = %FacePreviewPresenter


func _ready() -> void:
	if not RunManager.is_run_started():
		RunManager.start_run()

	_hover_presenter.setup(_popup_overlay)
	_hover_presenter.set_active(true)
	_shop_presenter.setup(_shop_dice_row, _pool_grid, _hover_presenter)
	_shop_presenter.pending_changed.connect(_on_pending_changed)
	_confirm_button.pressed.connect(_on_confirm_pressed)
	_continue_button.pressed.connect(_on_continue_pressed)

	RunManager.gold_changed.connect(_on_gold_changed)
	_refresh_shop()
	_set_default_status()


func _refresh_shop() -> void:
	_sync_header()
	_shop_presenter.refresh(
		RunManager.get_dice_roster(),
		RunManager.get_shop_offers(),
		RunManager.gold,
	)


func _sync_header() -> void:
	_floor_label.text = "상점 · 층 %d" % RunManager.current_floor
	_gold_label.text = "골드: %d" % RunManager.gold
	_continue_button.disabled = RunManager.run_finished


# 대기 라벨·확인 버튼만 갱신한다. 상태 문구는 명시적 동작(드롭·확인)에서만 바꿔,
# 새로고침(refresh)이 성공 메시지를 덮지 않게 한다.
func _on_pending_changed(count: int, cost: int) -> void:
	if count <= 0:
		_pending_label.text = ""
		_confirm_button.disabled = true
		return

	var affordable := RunManager.gold >= cost
	_pending_label.text = "구매 대기 %d개 · %d골드" % [count, cost]
	if affordable:
		_pending_label.add_theme_color_override("font_color", Color(0.36, 0.55, 0.3, 1))
	else:
		_pending_label.add_theme_color_override("font_color", Color(0.78, 0.28, 0.2, 1))
	_confirm_button.disabled = not affordable

	if affordable:
		_set_status("확인을 누르면 %d골드로 구매합니다." % cost)
	else:
		_set_status("골드가 부족합니다. (필요 %d · 보유 %d)" % [cost, RunManager.gold])


func _set_default_status() -> void:
	var earned := RunManager.shop_entry_gold_earned
	if earned > 0:
		_status_label.text = "+%d 골드! 상점 주사위를 보유 칸으로 끌어다 놓으세요." % earned
	else:
		_status_label.text = "상점 주사위를 보유 칸으로 끌어다 놓고 확인을 누르세요."


func _set_status(message: String) -> void:
	_status_label.text = message


func _on_confirm_pressed() -> void:
	var entries: Array = _shop_presenter.get_pending_entries()
	if entries.is_empty():
		return

	if RunManager.purchase_dice_batch(entries):
		# purchase_dice_batch가 gold_changed를 emit → _refresh_shop이 이미 돈다.
		_shop_presenter.clear_pending()
		_refresh_shop()
		_set_status("구매 완료! 계속 구매하거나 다음 층으로 이동하세요.")
	else:
		_set_status("구매에 실패했습니다.")


func _on_continue_pressed() -> void:
	_hover_presenter.hide_preview()
	_shop_presenter.clear_pending()
	RunManager.advance_floor()
	GameFlow.show_run()


func _on_gold_changed(amount: int) -> void:
	_gold_label.text = "골드: %d" % amount
	_refresh_shop()
