class_name HandStep
extends RefCounted

var hand_id: String
var display_ko: String
var highlight_indices: Array[int] = []
var points_added: int = 1
var clear_before: bool = false


func _init(
	p_hand_id: String,
	p_display_ko: String,
	p_highlight_indices: Array[int],
	p_points_added: int = 1,
	p_clear_before: bool = false,
) -> void:
	hand_id = p_hand_id
	display_ko = p_display_ko
	highlight_indices = p_highlight_indices
	points_added = p_points_added
	clear_before = p_clear_before
