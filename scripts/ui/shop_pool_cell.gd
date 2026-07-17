class_name ShopPoolCell
extends PanelContainer

const DICE_SCENE := preload("res://scenes/dice/dice.tscn")
const CELL_SIZE := Vector2(64, 64)

signal offer_dropped(cell_index: int, dice_id: String)
signal cell_clicked(cell_index: int)
signal cell_hovered(cell_index: int, resource: Resource)
signal cell_unhovered

enum State { EMPTY, OWNED, PENDING }

var cell_index: int = -1

var _state: int = State.EMPTY
var _drop_hovered := false
var _dice_view: Control
var _holder: CenterContainer
var _resource: Resource
var _press_pending := false


func _ready() -> void:
	custom_minimum_size = CELL_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	_holder = CenterContainer.new()
	_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_holder)
	_apply_style()


func set_cell_index(index: int) -> void:
	cell_index = index


func show_die(resource: Resource, state: int) -> void:
	_resource = resource
	_state = state
	_clear_dice_view()

	_dice_view = DICE_SCENE.instantiate()
	_dice_view.custom_minimum_size = Vector2(44, 44)
	_dice_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_holder.add_child(_dice_view)

	if resource == null:
		_dice_view.show_placeholder()
	else:
		var preview_face: Resource = resource.get_roster_preview_face()
		if preview_face == null:
			_dice_view.show_placeholder()
		else:
			_dice_view.set_face(preview_face, resource.get_roster_preview_value())
	_apply_style()


func show_empty() -> void:
	_resource = null
	_state = State.EMPTY
	_clear_dice_view()
	_apply_style()


func get_resource() -> Resource:
	return _resource


func _clear_dice_view() -> void:
	if _dice_view != null:
		_dice_view.queue_free()
		_dice_view = null


func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	if mouse_event.pressed:
		_press_pending = true
	elif _press_pending:
		_press_pending = false
		cell_clicked.emit(cell_index)


func _can_drop_data(_at_position: Vector2, data) -> bool:
	var ok := typeof(data) == TYPE_DICTIONARY and str(data.get("type", "")) == "shop_offer"
	_set_drop_hovered(ok)
	return ok


func _drop_data(_at_position: Vector2, data) -> void:
	_set_drop_hovered(false)
	if typeof(data) != TYPE_DICTIONARY:
		return
	offer_dropped.emit(cell_index, str(data.get("dice_id", "")))


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		_set_drop_hovered(false)
	elif what == NOTIFICATION_MOUSE_ENTER:
		if _resource != null:
			cell_hovered.emit(cell_index, _resource)
	elif what == NOTIFICATION_MOUSE_EXIT:
		cell_unhovered.emit()


func _set_drop_hovered(on: bool) -> void:
	if _drop_hovered == on:
		return
	_drop_hovered = on
	_apply_style()


func _apply_style() -> void:
	var style := StyleBoxFlat.new()
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)

	match _state:
		State.OWNED:
			style.bg_color = Color(0.9, 0.87, 0.78, 1.0)
			style.border_color = Color(0.68, 0.61, 0.48, 1.0)
		State.PENDING:
			style.bg_color = Color(0.86, 0.95, 0.84, 1.0)
			style.border_color = Color(0.36, 0.68, 0.32, 1.0)
			style.set_border_width_all(3)
		_:
			style.bg_color = Color(0.86, 0.84, 0.78, 0.5)
			style.border_color = Color(0.66, 0.62, 0.54, 0.7)

	if _drop_hovered:
		style.bg_color = Color(0.96, 0.91, 0.75, 1.0)
		style.border_color = Color(0.88, 0.58, 0.14, 1.0)
		style.set_border_width_all(3)

	add_theme_stylebox_override("panel", style)
