extends Node

const CatalogService := preload("res://scripts/core/dice_catalog_service.gd")


func _ready() -> void:
	CatalogService.shared().reload()
