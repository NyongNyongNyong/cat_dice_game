class_name ShopOfferDie
extends PanelContainer

const DICE_SCENE := preload("res://scenes/dice/dice.tscn")
const DIE_SIZE := Vector2(48, 48)
const SOLD_OUT_BG := Color(0.9, 0.88, 0.84, 1.0)

@onready var _dice_holder: CenterContainer = %DiceHolder

var dice_id: String = ""
var draggable: bool = true

var _resource: Resource
var _dice_view: Control
var _base_style: StyleBoxFlat


func _ready() -> void:
	_base_style = get_theme_stylebox("panel") as StyleBoxFlat


func configure(resource: Resource, id: String, can_drag: bool) -> void:
	dice_id = id
	draggable = can_drag
	_resource = resource
	mouse_filter = Control.MOUSE_FILTER_STOP
	_apply_style()
	_build_dice_view()


func _build_dice_view() -> void:
	if _dice_view != null:
		_dice_view.queue_free()
		_dice_view = null

	_dice_view = DICE_SCENE.instantiate()
	_dice_view.custom_minimum_size = DIE_SIZE
	_dice_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dice_holder.add_child(_dice_view)
	_apply_preview_face()


func _apply_preview_face() -> void:
	if _dice_view == null:
		return
	if _resource == null:
		_dice_view.show_placeholder()
		return
	var preview_face: Resource = _resource.get_roster_preview_face()
	if preview_face == null:
		_dice_view.show_placeholder()
	else:
		_dice_view.set_face(preview_face, _resource.get_roster_preview_value())


func get_resource() -> Resource:
	return _resource


func _get_drag_data(_at_position: Vector2):
	if not draggable or dice_id.is_empty():
		return null
	set_drag_preview(_build_drag_preview())
	return {"type": "shop_offer", "dice_id": dice_id}


func _build_drag_preview() -> Control:
	var preview := CenterContainer.new()
	preview.custom_minimum_size = DIE_SIZE
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.modulate = Color(1, 1, 1, 0.88)

	var clone: Control = DICE_SCENE.instantiate()
	clone.custom_minimum_size = DIE_SIZE
	clone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _dice_view != null and clone.has_method("copy_visual_state_from"):
		clone.copy_visual_state_from(_dice_view)
	clone.scale = Vector2(1.08, 1.08)
	preview.add_child(clone)
	return preview


# 살 수 있는 카드는 씬·Theme 스타일을 그대로 쓰고, 구매 불가일 때만 배경을 죽인다.
func _apply_style() -> void:
	if draggable or _base_style == null:
		remove_theme_stylebox_override("panel")
		return

	var style := _base_style.duplicate() as StyleBoxFlat
	style.bg_color = SOLD_OUT_BG
	add_theme_stylebox_override("panel", style)
