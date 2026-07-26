class_name ShopPoolCell
extends PanelContainer

const DICE_SCENE := preload("res://scenes/dice/dice.tscn")
const CELL_SIZE := Vector2(64, 64)
const OWNED_BG := Color(0.9, 0.87, 0.78, 1.0)
const OWNED_BORDER := Color(0.68, 0.61, 0.48, 1.0)
const PENDING_BG := Color(0.86, 0.95, 0.84, 1.0)
const PENDING_BORDER := Color(0.36, 0.68, 0.32, 1.0)
const DROP_BG := Color(0.96, 0.91, 0.75, 1.0)
const DROP_BORDER := Color(0.88, 0.58, 0.14, 1.0)

signal offer_dropped(cell_index: int, dice_id: String)
signal cell_clicked(cell_index: int)
signal cell_hovered(cell_index: int, resource: Resource)
signal cell_unhovered

enum State { EMPTY, OWNED, PENDING }

@onready var _holder: CenterContainer = %DiceHolder

var cell_index: int = -1

var _state: int = State.EMPTY
var _drop_hovered := false
var _dice_view: Control
var _resource: Resource
var _press_pending := false
var _base_style: StyleBoxFlat


func _ready() -> void:
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = CELL_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	# 빈 칸 스타일은 씬에서 온다. 상태 색은 그 사본 위에 얹는다.
	_base_style = get_theme_stylebox("panel") as StyleBoxFlat
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
	var accent := _build_accent_style()
	if accent == null:
		remove_theme_stylebox_override("panel")
		return
	add_theme_stylebox_override("panel", accent)


# 빈 칸(기본 상태)에서는 null을 돌려줘 씬·Theme 스타일을 그대로 쓰게 한다.
func _build_accent_style() -> StyleBoxFlat:
	var bg: Color
	var border: Color
	var border_width := 2

	if _drop_hovered:
		bg = DROP_BG
		border = DROP_BORDER
		border_width = 3
	else:
		match _state:
			State.OWNED:
				bg = OWNED_BG
				border = OWNED_BORDER
			State.PENDING:
				bg = PENDING_BG
				border = PENDING_BORDER
				border_width = 3
			_:
				return null

	var style := _duplicate_base_style()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	return style


func _duplicate_base_style() -> StyleBoxFlat:
	if _base_style != null:
		return _base_style.duplicate() as StyleBoxFlat

	var fallback := StyleBoxFlat.new()
	fallback.set_border_width_all(2)
	fallback.set_corner_radius_all(6)
	return fallback
