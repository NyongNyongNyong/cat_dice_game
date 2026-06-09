extends Node

signal continue_pressed
signal replace_requested(slot_index: int)

const CatalogService := preload("res://scripts/core/dice_catalog_service.gd")

const ROW_BUTTON_MIN := Vector2(88, 36)

var _panel: PanelContainer
var _offer_name_label: Label
var _slots_container: VBoxContainer
var _continue_button: Button
var _offer_dice_id: String = ""


func setup(
	panel: PanelContainer,
	offer_name_label: Label,
	slots_container: VBoxContainer,
	continue_button: Button
) -> void:
	_panel = panel
	_offer_name_label = offer_name_label
	_slots_container = slots_container
	_continue_button = continue_button
	_continue_button.pressed.connect(_on_continue_pressed)


func open(roster: RefCounted, offer_dice_id: String) -> void:
	_offer_dice_id = offer_dice_id
	_update_offer_label()
	_rebuild_slots(roster)
	_panel.visible = true


func close() -> void:
	_panel.visible = false


func is_open() -> bool:
	return _panel != null and _panel.visible


func _update_offer_label() -> void:
	var catalog = CatalogService.shared()
	if _offer_name_label == null:
		return
	if not catalog.has_dice(_offer_dice_id):
		_offer_name_label.text = "오퍼 없음"
		return
	_offer_name_label.text = catalog.get_display_name(_offer_dice_id)


func _rebuild_slots(roster: RefCounted) -> void:
	for child in _slots_container.get_children():
		child.queue_free()

	var catalog = CatalogService.shared()
	var can_replace: bool = catalog.has_dice(_offer_dice_id)

	for i in roster.get_count():
		var row := HBoxContainer.new()
		row.layout_mode = 2
		row.add_theme_constant_override("separation", 12)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var label := Label.new()
		label.layout_mode = 2
		var die: Resource = roster.get_dice_resource(i)
		var die_name := "주사위"
		if die != null and die.get("display_name"):
			die_name = str(die.display_name)
		label.text = "슬롯 %d · %s" % [i + 1, die_name]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.clip_text = true
		row.add_child(label)

		var replace_button := Button.new()
		replace_button.layout_mode = 2
		replace_button.text = "교체"
		replace_button.tooltip_text = "%s로 교체" % catalog.get_display_name(_offer_dice_id)
		replace_button.custom_minimum_size = ROW_BUTTON_MIN
		replace_button.size_flags_horizontal = Control.SIZE_SHRINK_END
		replace_button.disabled = not can_replace
		replace_button.pressed.connect(_on_replace_pressed.bind(i))
		row.add_child(replace_button)

		_slots_container.add_child(row)


func _on_replace_pressed(slot_index: int) -> void:
	replace_requested.emit(slot_index)


func _on_continue_pressed() -> void:
	continue_pressed.emit()
