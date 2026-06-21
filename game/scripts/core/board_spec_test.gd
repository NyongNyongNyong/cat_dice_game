extends SceneTree

const RunManagerScript := preload("res://scripts/autoload/run_manager.gd")

var _failed := 0


func _init() -> void:
	var rm: Node = RunManagerScript.new()
	rm.start_run()

	# 시작 상태: 4칸 해금, 빈 보드, 보유 4개
	_expect(rm.get_unlocked_slot_count() == RunManagerScript.STARTING_UNLOCKED_SLOTS, "start unlocked = 4")
	_expect(rm.board_placement.size() == RunManagerScript.BOARD_CELLS, "board has 12 cells")
	_expect(rm.get_placed_count() == 0, "start placed = 0")
	_expect(rm.get_owned_dice_count() == 4, "starter owns 4")

	# 잠금 칸(>=4)에는 배치 불가
	_expect(rm.place_die(0, 5) == false, "cannot place on locked cell 5")
	_expect(rm.get_placed_count() == 0, "locked placement no-op")

	# 해금 칸 배치
	_expect(rm.place_die(0, 0) == true, "place owned 0 -> cell 0")
	_expect(rm.get_owned_index_at(0) == 0, "cell 0 holds owned 0")
	_expect(rm.place_die(1, 3) == true, "place owned 1 -> cell 3")
	_expect(rm.get_placed_count() == 2, "placed = 2")
	_expect(rm.get_placed_dice().size() == 2, "placed dice resources = 2")
	var placed_order: Array = rm.get_placed_owned_indices()
	_expect(placed_order.size() == 2 and placed_order[0] == 0 and placed_order[1] == 1, "placed order by cell")

	# 같은 주사위 이동 (cell 0 -> cell 1)
	_expect(rm.place_die(0, 1) == true, "move owned 0 -> cell 1")
	_expect(rm.get_owned_index_at(0) == -1, "cell 0 now empty")
	_expect(rm.get_owned_index_at(1) == 0, "cell 1 holds owned 0")
	_expect(rm.get_placed_count() == 2, "still 2 placed after move")

	# 회수
	_expect(rm.clear_cell(1) == true, "clear cell 1")
	_expect(rm.get_placed_count() == 1, "placed = 1 after clear")
	_expect(rm.clear_cell(1) == false, "clear empty cell no-op")

	# 슬롯 해금
	_expect(rm.place_die(2, 4) == false, "cell 4 locked before unlock")
	_expect(rm.unlock_next_slot() == true, "unlock slot 5")
	_expect(rm.get_unlocked_slot_count() == 5, "unlocked = 5")
	_expect(rm.place_die(2, 4) == true, "cell 4 placeable after unlock")

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
