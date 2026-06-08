extends Node

signal continue_pressed
signal replace_requested(slot_index: int)

const DiceRosterScript := preload("res://scripts/core/dice_roster.gd")

var _panel: PanelContainer
var _slots_container: VBoxContainer
var _continue_button: Button


func setup(panel: PanelContainer, slots_container: VBoxContainer, continue_button: Button) -> void:
	_panel = panel
	_slots_container = slots_container
	_continue_button = continue_button
	_continue_button.pressed.connect(_on_continue_pressed)


func open(roster: RefCounted) -> void:
	_rebuild_slots(roster)
	_panel.visible = true


func close() -> void:
	_panel.visible = false


func is_open() -> bool:
	return _panel != null and _panel.visible


func _rebuild_slots(roster: RefCounted) -> void:
	for child in _slots_container.get_children():
		child.queue_free()

	for i in roster.get_count():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)

		var label := Label.new()
		var die: Resource = roster.get_dice_resource(i)
		var die_name := "주사위"
		if die != null and die.get("display_name"):
			die_name = str(die.display_name)
		label.text = "슬롯 %d: %s" % [i + 1, die_name]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)

		var replace_button := Button.new()
		replace_button.text = "H 주사위로 교체"
		replace_button.pressed.connect(_on_replace_pressed.bind(i))
		row.add_child(replace_button)

		_slots_container.add_child(row)


func _on_replace_pressed(slot_index: int) -> void:
	replace_requested.emit(slot_index)


func _on_continue_pressed() -> void:
	continue_pressed.emit()
