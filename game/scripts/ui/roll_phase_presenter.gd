class_name RollPhasePresenter
extends Node

## 굴림 phase 연출. v0.1: 플레이스홀더. 추후 3D 주사위 던지기로 교체.

const ROLL_DURATION := 0.6

signal presentation_finished()

var _roll_slot: Control
var _dice_row: Control


func setup(roll_slot: Control, dice_row: Control) -> void:
	_roll_slot = roll_slot
	_dice_row = dice_row


func play(_values: Array[int]) -> void:
	_roll_slot.visible = true
	_dice_row.visible = false

	# TODO: 3D 주사위 던지기 연출로 교체
	await get_tree().create_timer(ROLL_DURATION).timeout

	_roll_slot.visible = false
	presentation_finished.emit()
