extends SceneTree

const RunManagerScript := preload("res://scripts/autoload/run_manager.gd")

var _failed := 0


func _init() -> void:
	var rm: Node = RunManagerScript.new()
	rm.start_run()

	_expect(rm.get_unlocked_slot_count() == RunManagerScript.STARTING_UNLOCKED_SLOTS, "start unlocked = 4")
	_expect(rm.board_placement.size() == RunManagerScript.BOARD_CELLS, "board has 12 cells")
	_expect(RunManagerScript.BOARD_COLS == 4, "board has 4 columns")
	_expect(RunManagerScript.BOARD_ROWS == 3, "board has 3 rows")
	_expect(rm.get_placed_count() == 0, "start placed = 0")
	_expect(rm.get_owned_dice_count() == 4, "starter owns 4")

	_expect(rm.place_die(0, 0) == false, "cannot place on locked top-row cell 0")
	_expect(rm.get_placed_count() == 0, "locked placement no-op")

	_expect(rm.is_slot_unlocked(4) == true, "middle row cell 4 unlocked")
	_expect(rm.is_slot_unlocked(7) == true, "middle row cell 7 unlocked")
	_expect(rm.is_slot_unlocked(8) == false, "bottom row cell 8 locked at start")
	_expect(rm.place_die(0, 4) == true, "place owned 0 -> cell 4")
	_expect(rm.get_owned_index_at(4) == 0, "cell 4 holds owned 0")
	_expect(rm.place_die(1, 7) == true, "place owned 1 -> cell 7")
	_expect(rm.get_placed_count() == 2, "placed = 2")
	_expect(rm.get_placed_dice().size() == 2, "placed dice resources = 2")
	var placed_order: Array = rm.get_placed_owned_indices()
	_expect(placed_order.size() == 2 and placed_order[0] == 0 and placed_order[1] == 1, "placed order by cell")

	_expect(rm.place_die(0, 5) == true, "move owned 0 -> cell 5")
	_expect(rm.get_owned_index_at(4) == -1, "cell 4 now empty")
	_expect(rm.get_owned_index_at(5) == 0, "cell 5 holds owned 0")
	_expect(rm.get_placed_count() == 2, "still 2 placed after move")

	_expect(rm.clear_cell(5) == true, "clear cell 5")
	_expect(rm.get_placed_count() == 1, "placed = 1 after clear")
	_expect(rm.clear_cell(5) == false, "clear empty cell no-op")

	_expect(rm.place_die(2, 8) == false, "cell 8 locked before unlock")
	_expect(rm.unlock_next_slot() == true, "unlock fifth slot")
	_expect(rm.get_unlocked_slot_count() == 5, "unlocked = 5")
	_expect(rm.place_die(2, 8) == true, "cell 8 placeable after unlock")

	rm.free()

	if _failed > 0:
		push_error("Board spec tests failed: %d" % _failed)
	quit(_failed)


func _expect(condition: bool, label: String) -> void:
	if condition:
		print("  OK  %s" % label)
	else:
		print("FAIL  %s" % label)
		_failed += 1
