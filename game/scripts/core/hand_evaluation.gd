class_name HandEvaluation
extends RefCounted

const HandStep := preload("res://scripts/core/hand_step.gd")

var dice_values: Array[int] = []
var steps: Array[HandStep] = []
var number_sum: int = 0
var hand_value_sum: int = 0
var total_score: int = 0
