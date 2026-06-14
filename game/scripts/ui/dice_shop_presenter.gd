extends Node

signal continue_pressed
signal purchase_requested(dice_id: String, slot_index: int)
signal selection_changed(has_offer: bool)

const CatalogService := preload("res://scripts/core/dice_catalog_service.gd")
const DICE_SCENE := preload("res://scenes/dice/dice.tscn")

const DICE_VIEW_SIZE := Vector2(56, 56)
const ROW_SEPARATION := 12
const OFFER_SEPARATION := 16
const SHOP_SLOT_TEXT_COLOR := Color(0.18, 0.15, 0.12, 1)
const SHOP_SLOT_FONT_SIZE := 16
const OFFER_PRICE_COLOR := Color(0.72, 0.55, 0.12, 1)
const OFFER_DISABLED_COLOR := Color(0.55, 0.5, 0.45, 1)

var _offer_container: HBoxContainer
var _roster_container: VBoxContainer
var _continue_button: Button
var _hover_presenter: Node

var _selected_offer_id: String = ""
var _offer_dice_views: Array[Control] = []
var _roster_dice_views: Array[Control] = []
var _offer_ids: Array[String] = []


func setup(
	offer_container: HBoxContainer,
	roster_container: VBoxContainer,
	continue_button: Button,
	hover_presenter: Node = null,
) -> void:
	_offer_container = offer_container
	_roster_container = roster_container
	_continue_button = continue_button
	_hover_presenter = hover_presenter
	_continue_button.pressed.connect(_on_continue_pressed)


func refresh(roster: RefCounted, offers: Array[Dictionary], gold: int) -> void:
	_rebuild_offers(offers, gold)
	_rebuild_roster(roster)
	_apply_offer_selection_visuals()


func get_selected_offer_id() -> String:
	return _selected_offer_id


func clear_selection() -> void:
	if _selected_offer_id.is_empty():
		return
	_selected_offer_id = ""
	_apply_offer_selection_visuals()
	selection_changed.emit(false)


func _rebuild_offers(offers: Array[Dictionary], gold: int) -> void:
	for child in _offer_container.get_children():
		child.queue_free()
	_offer_dice_views.clear()
	_offer_ids.clear()

	var catalog = CatalogService.shared()
	for offer in offers:
		var dice_id: String = str(offer.get("dice_id", ""))
		if dice_id.is_empty() or not catalog.has_dice(dice_id):
			continue

		var price: int = int(offer.get("price_gold", 0))
		var can_afford := gold >= price
		_offer_ids.append(dice_id)

		var card := _make_offer_card(dice_id, price, can_afford, catalog)
		_offer_container.add_child(card)


func _make_offer_card(dice_id: String, price: int, can_afford: bool, catalog) -> Control:
	var card := PanelContainer.new()
	card.layout_mode = 2
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.98, 0.96, 0.92, 1.0)
	style.border_color = Color(0.72, 0.66, 0.52, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 10.0
	style.content_margin_top = 10.0
	style.content_margin_right = 10.0
	style.content_margin_bottom = 10.0
	card.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.layout_mode = 2
	vbox.add_theme_constant_override("separation", 6)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(vbox)

	var dice_view := _make_dice_view(catalog.get_dice(dice_id))
	dice_view.modulate = Color.WHITE if can_afford else Color(0.72, 0.72, 0.72, 1.0)
	dice_view.gui_input.connect(_on_offer_gui_input.bind(dice_id, can_afford))
	dice_view.mouse_entered.connect(_on_offer_mouse_entered.bind(dice_view, dice_id))
	dice_view.mouse_exited.connect(_on_dice_mouse_exited)
	vbox.add_child(_wrap_dice_center(dice_view))
	_offer_dice_views.append(dice_view)

	var name_label := Label.new()
	name_label.layout_mode = 2
	name_label.text = catalog.get_display_name(dice_id)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", SHOP_SLOT_TEXT_COLOR)
	name_label.add_theme_font_size_override("font_size", SHOP_SLOT_FONT_SIZE)
	vbox.add_child(name_label)

	var price_label := Label.new()
	price_label.layout_mode = 2
	price_label.text = "%d 골드" % price
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_label.add_theme_color_override(
		"font_color",
		OFFER_PRICE_COLOR if can_afford else OFFER_DISABLED_COLOR
	)
	price_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(price_label)

	card.gui_input.connect(_on_offer_gui_input.bind(dice_id, can_afford))
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	return card


func _rebuild_roster(roster: RefCounted) -> void:
	for child in _roster_container.get_children():
		child.queue_free()
	_roster_dice_views.clear()

	var catalog = CatalogService.shared()
	for i in roster.get_count():
		var row := HBoxContainer.new()
		row.layout_mode = 2
		row.add_theme_constant_override("separation", ROW_SEPARATION)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var label := Label.new()
		label.layout_mode = 2
		label.text = "슬롯 %d" % [i + 1]
		label.custom_minimum_size = Vector2(64, 0)
		label.add_theme_color_override("font_color", SHOP_SLOT_TEXT_COLOR)
		label.add_theme_font_size_override("font_size", SHOP_SLOT_FONT_SIZE)
		row.add_child(label)

		var resource: Resource = roster.get_dice_resource(i)
		var dice_view := _make_dice_view(resource)
		dice_view.gui_input.connect(_on_roster_gui_input.bind(i))
		dice_view.mouse_entered.connect(_on_roster_mouse_entered.bind(dice_view, resource))
		dice_view.mouse_exited.connect(_on_dice_mouse_exited)
		row.add_child(_wrap_dice_center(dice_view))
		_roster_dice_views.append(dice_view)

		var name_label := Label.new()
		name_label.layout_mode = 2
		name_label.text = _get_die_display_name(resource, catalog)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.clip_text = true
		name_label.add_theme_color_override("font_color", SHOP_SLOT_TEXT_COLOR)
		name_label.add_theme_font_size_override("font_size", SHOP_SLOT_FONT_SIZE)
		row.add_child(name_label)

		_roster_container.add_child(row)


func _make_dice_view(resource: Resource) -> Control:
	var dice_view: Control = DICE_SCENE.instantiate()
	dice_view.custom_minimum_size = DICE_VIEW_SIZE
	dice_view.layout_mode = 2
	dice_view.mouse_filter = Control.MOUSE_FILTER_STOP
	dice_view.focus_mode = Control.FOCUS_NONE

	if resource == null:
		dice_view.show_placeholder()
	else:
		var preview_face: Resource = resource.get_roster_preview_face()
		if preview_face == null:
			dice_view.show_placeholder()
		else:
			dice_view.set_face(preview_face, resource.get_roster_preview_value())
	return dice_view


func _wrap_dice_center(dice_view: Control) -> CenterContainer:
	var center := CenterContainer.new()
	center.layout_mode = 2
	center.custom_minimum_size = DICE_VIEW_SIZE
	center.add_child(dice_view)
	return center


func _get_die_display_name(resource: Resource, catalog) -> String:
	if resource == null:
		return "주사위"
	var dice_id := str(resource.id)
	if not dice_id.is_empty() and catalog.has_dice(dice_id):
		return catalog.get_display_name(dice_id)
	if resource.get("display_name"):
		return str(resource.display_name)
	return "주사위"


func _on_offer_gui_input(event: InputEvent, dice_id: String, can_afford: bool) -> void:
	if not can_afford:
		return
	if not event is InputEventMouseButton:
		return
	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	_select_offer(dice_id)


func _select_offer(dice_id: String) -> void:
	if _selected_offer_id == dice_id:
		clear_selection()
		return
	_selected_offer_id = dice_id
	_apply_offer_selection_visuals()
	selection_changed.emit(true)


func _apply_offer_selection_visuals() -> void:
	for i in _offer_dice_views.size():
		var dice_view: Control = _offer_dice_views[i]
		var selected := i < _offer_ids.size() and _offer_ids[i] == _selected_offer_id
		if dice_view.has_method("set_selected"):
			dice_view.set_selected(selected)


func _on_roster_gui_input(event: InputEvent, slot_index: int) -> void:
	if _selected_offer_id.is_empty():
		return
	if not event is InputEventMouseButton:
		return
	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	purchase_requested.emit(_selected_offer_id, slot_index)


func _on_offer_mouse_entered(dice_view: Control, dice_id: String) -> void:
	_show_hover_for_catalog_id(dice_view, dice_id)


func _on_roster_mouse_entered(dice_view: Control, resource: Resource) -> void:
	if resource == null:
		return
	_show_hover_for_resource(dice_view, resource)


func _show_hover_for_catalog_id(dice_view: Control, dice_id: String) -> void:
	var die: Resource = CatalogService.shared().get_dice(dice_id)
	if die == null:
		return
	_show_hover_for_resource(dice_view, die)


func _show_hover_for_resource(dice_view: Control, resource: Resource) -> void:
	if _hover_presenter == null or not _hover_presenter.has_method("show_die_faces"):
		return
	var faces: Array[Resource] = resource.get_faces()
	if faces.is_empty():
		return
	_hover_presenter.set_active(true)
	_hover_presenter.show_die_faces(dice_view, faces, faces, -1)


func _on_dice_mouse_exited() -> void:
	if _hover_presenter != null and _hover_presenter.has_method("hide_preview"):
		_hover_presenter.hide_preview()


func _on_continue_pressed() -> void:
	continue_pressed.emit()
