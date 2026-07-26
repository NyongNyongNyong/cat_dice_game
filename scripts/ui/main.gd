extends Control

const RUN_SCENE := preload("res://scenes/game/run_scene.tscn")
const SHOP_SCENE := preload("res://scenes/game/shop_scene.tscn")

@onready var _ui: Control = %UI

var _current_scene: Control


func _ready() -> void:
	GameFlow.run_requested.connect(_show_run)
	GameFlow.shop_requested.connect(_show_shop)
	_show_run()


func _show_run() -> void:
	_swap_scene(RUN_SCENE)


func _show_shop() -> void:
	_swap_scene(SHOP_SCENE)


func _swap_scene(packed: PackedScene) -> void:
	# 직전에 띄운 씬만 정리한다. %UI에 배경·장식 노드를 같이 두어도 살아남는다.
	if _current_scene != null and is_instance_valid(_current_scene):
		_current_scene.queue_free()

	var scene: Control = packed.instantiate()
	_current_scene = scene
	_ui.add_child(scene)
	scene.set_anchors_preset(Control.PRESET_FULL_RECT)
	scene.set_offsets_preset(Control.PRESET_FULL_RECT)
