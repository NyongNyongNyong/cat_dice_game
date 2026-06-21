class_name DiceSlot
extends PanelContainer

const DICE_SCENE := preload("res://scenes/dice/dice.tscn")

signal clicked(slot_index: int)
signal drag_started(slot_index: int)
signal drop_requested(from_index: int, to_index: int)

const SLOT_SIZE := Vector2(76, 76)
const NORMAL_BG := Color(0.9, 0.87, 0.78, 1.0)
const NORMAL_BORDER := Color(0.68, 0.61, 0.48, 1.0)
const SELECTED_BG := Color(0.86, 0.9, 0.98, 1.0)
const SELECTED_BORDER := Color(0.22, 0.48, 0.86, 1.0)
const DROP_BG := Color(0.96, 0.91, 0.75, 1.0)
const DROP_BORDER := Color(0.88, 0.58, 0.14, 1.0)
const LOCKED_BG := Color(0.82, 0.79, 0.72, 0.4)
const LOCKED_BORDER := Color(0.6, 0.56, 0.48, 0.45)
const DRAG_SOURCE_ALPHA := 0.28

@export var slot_index := -1

@onready var _dice_holder: CenterContainer = %DiceHolder

var _dice_view: Control
var _selected := false
var _drop_hovered := false
var _dragging := false
var _drag_enabled := true
var _locked := false


func _ready() -> void:
	custom_minimum_size = SLOT_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	_apply_style()


func set_slot_index(index: int) -> void:
	slot_index = index


func set_dice_view(dice_view: Control) -> void:
	_dice_view = dice_view
	if _dice_view == null:
		return
	if _dice_view.get_parent() != null:
		_dice_view.get_parent().remove_child(_dice_view)
	_dice_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dice_view.layout_mode = 2
	_dice_view.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_dice_view.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_dice_holder.add_child(_dice_view)


func get_dice_view() -> Control:
	return _dice_view


func clear_dice_view() -> void:
	if _dice_view != null:
		_dice_view.queue_free()
		_dice_view = null


func set_selected(on: bool) -> void:
	_selected = on
	_apply_style()


func set_drop_hovered(on: bool) -> void:
	_drop_hovered = on
	_apply_style()


func set_drag_enabled(on: bool) -> void:
	_drag_enabled = on
	if not _drag_enabled:
		_set_dragging(false)
		set_drop_hovered(false)


func set_locked(on: bool) -> void:
	_locked = on
	mouse_filter = Control.MOUSE_FILTER_IGNORE if _locked else Control.MOUSE_FILTER_STOP
	_apply_style()


func _gui_input(event: InputEvent) -> void:
	if _locked:
		return
	if not event is InputEventMouseButton:
		return
	var mouse_event := event as InputEventMouseButton
	if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(slot_index)


func _get_drag_data(_at_position: Vector2):
	if not _drag_enabled:
		return null
	if _dice_view == null:
		return null

	drag_started.emit(slot_index)
	_set_dragging(true)
	set_drag_preview(_build_drag_preview())
	return {
		"type": "dice_slot",
		"slot_index": slot_index,
	}


func _can_drop_data(_at_position: Vector2, data) -> bool:
	if not _drag_enabled:
		set_drop_hovered(false)
		return false
	if typeof(data) != TYPE_DICTIONARY:
		set_drop_hovered(false)
		return false
	if str(data.get("type", "")) != "dice_slot":
		set_drop_hovered(false)
		return false
	var can_drop := int(data.get("slot_index", -1)) != slot_index
	set_drop_hovered(can_drop)
	return can_drop


func _drop_data(_at_position: Vector2, data) -> void:
	set_drop_hovered(false)
	if not _can_drop_data(_at_position, data):
		return
	drop_requested.emit(int(data["slot_index"]), slot_index)


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		_set_dragging(false)
		set_drop_hovered(false)


func _build_drag_preview() -> Control:
	var preview := CenterContainer.new()
	preview.custom_minimum_size = SLOT_SIZE
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.modulate = Color(1, 1, 1, 0.86)

	if _dice_view != null:
		var dice_clone := DICE_SCENE.instantiate() as Control
		if dice_clone != null:
			dice_clone.mouse_filter = Control.MOUSE_FILTER_IGNORE
			dice_clone.custom_minimum_size = _dice_view.custom_minimum_size
			if dice_clone.has_method("copy_visual_state_from"):
				dice_clone.copy_visual_state_from(_dice_view)
			dice_clone.scale = Vector2(1.08, 1.08)
			preview.add_child(dice_clone)

	return preview


func _set_dragging(on: bool) -> void:
	_dragging = on
	if _dice_view != null:
		_dice_view.modulate.a = DRAG_SOURCE_ALPHA if _dragging else 1.0


func _apply_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = NORMAL_BG
	style.border_color = NORMAL_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 6
	style.content_margin_top = 6
	style.content_margin_right = 6
	style.content_margin_bottom = 6

	if _locked:
		style.bg_color = LOCKED_BG
		style.border_color = LOCKED_BORDER
	elif _selected:
		style.bg_color = SELECTED_BG
		style.border_color = SELECTED_BORDER
		style.set_border_width_all(3)
	elif _drop_hovered:
		style.bg_color = DROP_BG
		style.border_color = DROP_BORDER
		style.set_border_width_all(3)

	add_theme_stylebox_override("panel", style)
