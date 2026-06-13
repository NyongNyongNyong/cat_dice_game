extends Control

@onready var _floor_label: Label = $MarginContainer/RootVBox/Header/FloorLabel
@onready var _gold_label: Label = $MarginContainer/RootVBox/Header/GoldLabel
@onready var _status_label: Label = $MarginContainer/RootVBox/StatusLabel
@onready var _offer_name_label: Label = (
	$MarginContainer/RootVBox/Scroll/ScrollContent/OfferPanel/OfferVBox/OfferName
)
@onready var _slots_container: VBoxContainer = (
	$MarginContainer/RootVBox/Scroll/ScrollContent/RosterSlots
)
@onready var _continue_button: Button = $MarginContainer/RootVBox/Footer/ContinueButton
@onready var _shop_presenter: Node = $DiceShopPresenter


func _ready() -> void:
	_shop_presenter.setup(_offer_name_label, _slots_container, _continue_button)
	_shop_presenter.continue_pressed.connect(_on_continue_pressed)
	_shop_presenter.replace_requested.connect(_on_replace_requested)

	RunManager.gold_changed.connect(_on_gold_changed)
	_sync_header()
	_shop_presenter.refresh(
		RunManager.get_dice_roster(),
		RunManager.get_shop_replace_offer_id()
	)


func _sync_header() -> void:
	_floor_label.text = "층: %d" % RunManager.current_floor
	_gold_label.text = "골드: %d" % RunManager.gold
	var earned := RunManager.shop_entry_gold_earned
	if earned > 0:
		_status_label.text = "+%d 골드 획득! 주사위를 교체한 뒤 다음 층으로 이동하세요." % earned
	else:
		_status_label.text = "주사위를 교체한 뒤 다음 층으로 이동하세요."
	_continue_button.disabled = RunManager.run_finished


func _on_replace_requested(slot_index: int) -> void:
	if RunManager.replace_owned_dice_at(slot_index, RunManager.get_shop_replace_offer_id()):
		_shop_presenter.refresh(
			RunManager.get_dice_roster(),
			RunManager.get_shop_replace_offer_id()
		)


func _on_continue_pressed() -> void:
	RunManager.advance_floor()
	GameFlow.show_run()


func _on_gold_changed(amount: int) -> void:
	_gold_label.text = "골드: %d" % amount
