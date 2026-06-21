class_name RoundController
extends Node

const DEFAULT_DICE_RESOURCE := preload("res://resources/dice/basic_d6.tres")
const RerollPreviewCalculator := preload("res://scripts/core/reroll_preview_calculator.gd")
const RoundPhase := preload("res://scripts/core/round_phase.gd")
const HandEvaluation := preload("res://scripts/core/hand_evaluation.gd")
const HandCalculator := preload("res://scripts/core/hand_calculator.gd")
const RunManagerScript := preload("res://scripts/autoload/run_manager.gd")
const LuckResolver := preload("res://scripts/core/luck_resolver.gd")

var _rng := RandomNumberGenerator.new()

signal phase_changed(phase: RoundPhase.Phase)
signal dice_rolled(values: Array[int])
signal die_selected(index: int)
signal die_rerolled(values: Array[int])
signal score_ready(evaluation: HandEvaluation)
signal round_reset()

@export var default_dice_resource: Resource = DEFAULT_DICE_RESOURCE
@export var dice_loadout: Resource
@export var dice_resources: Array[Resource] = []

var phase: RoundPhase.Phase = RoundPhase.Phase.IDLE
var dice_values: Array[int] = []
var dice_faces: Array[Resource] = []
var hand_evaluation: HandEvaluation
var selected_die_index: int = -1
var last_rerolled_die_index: int = -1


func _ready() -> void:
	_rng.randomize()


func begin_round() -> void:
	reset_round()


func reset_round() -> void:
	phase = RoundPhase.Phase.IDLE
	dice_values.clear()
	dice_faces.clear()
	hand_evaluation = null
	selected_die_index = -1
	last_rerolled_die_index = -1
	phase_changed.emit(phase)
	round_reset.emit()


func can_roll() -> bool:
	if phase == RoundPhase.Phase.IDLE or phase == RoundPhase.Phase.REROLL_READY:
		var run_manager := _get_run_manager()
		if run_manager == null:
			return true
		return run_manager.can_spend_chip()
	return false


func can_reroll_preview() -> bool:
	return false


func can_advance_floor() -> bool:
	return phase == RoundPhase.Phase.REROLL_READY


func roll() -> void:
	if dice_resources.is_empty() and dice_loadout == null:
		return
	if phase == RoundPhase.Phase.IDLE or phase == RoundPhase.Phase.REROLL_READY:
		_roll_all_dice()


func select_die(index: int) -> void:
	if not can_reroll_preview():
		return
	if index < 0 or index >= dice_values.size():
		return

	selected_die_index = index
	die_selected.emit(index)


func clear_selection() -> void:
	selected_die_index = -1


func get_face_values(dice_index: int) -> Array[int]:
	var resource := get_dice_resource(dice_index)
	if resource.has_method("get_face_values"):
		return resource.get_face_values()
	return DEFAULT_DICE_RESOURCE.get_face_values()


func get_dice_count() -> int:
	if dice_loadout != null and dice_loadout.has_method("get_dice_count"):
		var loadout_count: int = dice_loadout.get_dice_count()
		if loadout_count > 0:
			return loadout_count
	if not dice_resources.is_empty():
		return dice_resources.size()
	return RunManagerScript.DICE_COUNT


func get_reroll_face_values(dice_index: int) -> Array[int]:
	var resource := get_dice_resource(dice_index)
	var candidates: Array[Resource] = []
	if resource.has_method("get_faces"):
		candidates = resource.get_faces()
	else:
		candidates = DEFAULT_DICE_RESOURCE.get_faces()

	var values: Array[int] = []
	for candidate in candidates:
		var context_faces := dice_faces.duplicate()
		if dice_index >= 0 and dice_index < context_faces.size():
			context_faces[dice_index] = candidate
		else:
			context_faces.append(candidate)
		values.append(_resolve_face_value(candidate, context_faces))
	return values


func get_reroll_preview(dice_index: int):
	var resource := get_dice_resource(dice_index)
	var candidates: Array[Resource] = []
	if resource.has_method("get_faces"):
		candidates = resource.get_faces()
	else:
		candidates = DEFAULT_DICE_RESOURCE.get_faces()
	return RerollPreviewCalculator.compute_from_faces(dice_faces, dice_index, candidates)


func get_dice_resource(dice_index: int) -> Resource:
	if dice_loadout != null and dice_loadout.has_method("get_dice_resource"):
		var loadout_resource: Resource = dice_loadout.get_dice_resource(dice_index)
		if loadout_resource != null:
			return loadout_resource
	if dice_index >= 0 and dice_index < dice_resources.size() and dice_resources[dice_index] != null:
		return dice_resources[dice_index]
	if default_dice_resource != null:
		return default_dice_resource
	return DEFAULT_DICE_RESOURCE


func resolve_faces(faces: Array[Resource]) -> Array[int]:
	var values: Array[int] = []
	for face in faces:
		values.append(_resolve_face_value(face, faces))
	return values


func complete_roll_presentation() -> void:
	if phase != RoundPhase.Phase.ROLLING:
		return
	_begin_scoring()


func complete_score_presentation() -> void:
	if phase != RoundPhase.Phase.SCORING:
		return
	_set_phase(RoundPhase.Phase.REROLL_READY)


func _roll_all_dice() -> void:
	var run_manager := _get_run_manager()
	if run_manager != null and not run_manager.try_spend_chip():
		return
	_set_phase(RoundPhase.Phase.ROLLING)
	selected_die_index = -1
	last_rerolled_die_index = -1
	var luck := 0.0
	if run_manager != null:
		luck = run_manager.luck
	dice_faces = LuckResolver.resolve(
		dice_resources, luck, Callable(self, "resolve_faces"), _rng
	)
	dice_values = resolve_faces(dice_faces)
	dice_rolled.emit(dice_values)


func _begin_scoring() -> void:
	_set_phase(RoundPhase.Phase.SCORING)
	hand_evaluation = HandCalculator.evaluate(dice_values)
	score_ready.emit(hand_evaluation)


func _roll_dice_values() -> Array[int]:
	return resolve_faces(_roll_dice_faces())


func _roll_dice_faces() -> Array[Resource]:
	var rolled_faces: Array[Resource] = []
	for i in get_dice_count():
		rolled_faces.append(_roll_die_face(i))
	return rolled_faces


func _roll_die_value(dice_index: int) -> int:
	return _resolve_face_value(_roll_die_face(dice_index))


func _roll_die_face(dice_index: int) -> Resource:
	var resource := get_dice_resource(dice_index)
	if resource.has_method("roll_face"):
		return resource.roll_face()
	return DEFAULT_DICE_RESOURCE.roll_face()


func _resolve_face_value(face: Resource, context_faces: Array[Resource] = []) -> int:
	var resource := DEFAULT_DICE_RESOURCE
	if resource.has_method("resolve_face_value"):
		return resource.resolve_face_value(face, context_faces)
	return 1


func _set_phase(next_phase: RoundPhase.Phase) -> void:
	phase = next_phase
	phase_changed.emit(phase)


func _get_run_manager() -> Node:
	if not is_inside_tree():
		return null
	return get_tree().root.get_node_or_null("RunManager")
