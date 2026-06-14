extends Control

@onready var _floor_label: Label = $MarginContainer/RootVBox/Header/FloorLabel
@onready var _gold_label: Label = $MarginContainer/RootVBox/Header/GoldLabel
@onready var _status_label: Label = $MarginContainer/RootVBox/StatusLabel
@onready var _offer_container: HBoxContainer = (
	$MarginContainer/RootVBox/Scroll/ScrollContent/OfferPanel/OfferVBox/OfferRow
)
@onready var _slots_container: VBoxContainer = (
	$MarginContainer/RootVBox/Scroll/ScrollContent/RosterSlots
)
@onready var _continue_button: Button = $MarginContainer/RootVBox/Footer/ContinueButton
@onready var _popup_overlay: Control = $MarginContainer/RootVBox/PopupOverlay
@onready var _shop_presenter: Node = $DiceShopPresenter
@onready var _hover_presenter: Node = $RerollPreviewPresenter


func _ready() -> void:
	_hover_presenter.setup(_popup_overlay)
	_hover_presenter.set_active(true)
	_shop_presenter.setup(
		_offer_container, _slots_container, _continue_button, _hover_presenter
	)
	_shop_presenter.continue_pressed.connect(_on_continue_pressed)
	_shop_presenter.purchase_requested.connect(_on_purchase_requested)
	_shop_presenter.selection_changed.connect(_on_selection_changed)

	RunManager.gold_changed.connect(_on_gold_changed)
	_refresh_shop()


func _refresh_shop() -> void:
	_sync_header()
	_shop_presenter.refresh(
		RunManager.get_dice_roster(),
		RunManager.get_shop_offers(),
		RunManager.gold,
	)
	if not _shop_presenter.get_selected_offer_id().is_empty():
		_set_status("교체할 보유 주사위를 클릭하세요.")
	else:
		_set_default_status()


func _sync_header() -> void:
	_floor_label.text = "층: %d" % RunManager.current_floor
	_gold_label.text = "골드: %d" % RunManager.gold
	_continue_button.disabled = RunManager.run_finished


func _set_default_status() -> void:
	var earned := RunManager.shop_entry_gold_earned
	if earned > 0:
		_status_label.text = (
			"+%d 골드 획득! 구매할 주사위를 클릭한 뒤 교체할 슬롯을 클릭하세요." % earned
		)
	else:
		_status_label.text = "구매할 주사위를 클릭한 뒤 교체할 슬롯을 클릭하세요."


func _set_status(message: String) -> void:
	_status_label.text = message


func _on_purchase_requested(dice_id: String, slot_index: int) -> void:
	if not RunManager.can_afford_shop_offer(dice_id):
		_set_status("골드가 부족합니다.")
		_shop_presenter.clear_selection()
		_refresh_shop()
		return

	if RunManager.try_purchase_shop_replace(dice_id, slot_index):
		_shop_presenter.clear_selection()
		_set_status("교체 완료! 다른 주사위도 구매하거나 다음 층으로 이동하세요.")
		_refresh_shop()
	else:
		_set_status("교체에 실패했습니다.")
		_shop_presenter.clear_selection()
		_refresh_shop()


func _on_selection_changed(has_offer: bool) -> void:
	if has_offer:
		_set_status("교체할 보유 주사위를 클릭하세요.")
	else:
		_set_default_status()


func _on_continue_pressed() -> void:
	_hover_presenter.hide_preview()
	RunManager.advance_floor()
	GameFlow.show_run()


func _on_gold_changed(amount: int) -> void:
	_gold_label.text = "골드: %d" % amount
	_refresh_shop()
