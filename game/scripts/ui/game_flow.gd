extends Node

signal run_requested
signal shop_requested


func show_run() -> void:
	run_requested.emit()


func show_shop() -> void:
	shop_requested.emit()
