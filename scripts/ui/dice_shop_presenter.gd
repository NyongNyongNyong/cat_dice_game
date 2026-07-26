extends Node

signal pending_changed(count: int, cost: int)

const CatalogService := preload("res://scripts/core/dice_catalog_service.gd")
const SHOP_OFFER_DIE_SCENE := preload("res://scenes/ui/shop_offer_die.tscn")
const SHOP_POOL_CELL_SCENE := preload("res://scenes/ui/shop_pool_cell.tscn")

const POOL_CELLS := 8
const POOL_COLS := 4

var _shop_dice_row: HBoxContainer
var _pool_grid: GridContainer
var _hover_presenter: Node

# cell_index -> dice_id (대기 중인 구매). 확인 전까지 로스터를 바꾸지 않는다.
var _pending: Dictionary = {}
var _owned_count := 0
var _pool_cells: Array[Control] = []
var _offer_cards: Array[Control] = []


func setup(
	shop_dice_row: HBoxContainer,
	pool_grid: GridContainer,
	hover_presenter: Node = null,
) -> void:
	_shop_dice_row = shop_dice_row
	_pool_grid = pool_grid
	_pool_grid.columns = POOL_COLS
	_hover_presenter = hover_presenter


func refresh(roster: RefCounted, offers: Array[Dictionary], _gold: int) -> void:
	_owned_count = roster.get_count()
	_prune_invalid_pending()
	_rebuild_shop_dice(offers)
	_rebuild_pool(roster)
	_emit_pending_changed()


func get_pending_count() -> int:
	return _pending.size()


func get_pending_cost() -> int:
	return RunManager.SHOP_DICE_PRICE * _pending.size()


func get_pending_entries() -> Array:
	var entries: Array = []
	for cell in _pending:
		var action := "replace" if cell < _owned_count else "add"
		entries.append({
			"action": action,
			"slot": cell,
			"dice_id": str(_pending[cell]),
		})
	return entries


func clear_pending() -> void:
	if _pending.is_empty():
		return
	_pending.clear()
	_emit_pending_changed()


func _prune_invalid_pending() -> void:
	for cell in _pending.keys():
		if cell < 0 or cell >= POOL_CELLS:
			_pending.erase(cell)


func _rebuild_shop_dice(offers: Array[Dictionary]) -> void:
	# 코드가 만든 카드만 지운다. %ShopDiceRow에 장식 노드를 두어도 유지된다.
	for card in _offer_cards:
		if is_instance_valid(card):
			card.queue_free()
	_offer_cards.clear()

	var catalog = CatalogService.shared()
	for offer in offers:
		var dice_id: String = str(offer.get("dice_id", ""))
		if dice_id.is_empty() or not catalog.has_dice(dice_id):
			continue

		var card: Control = SHOP_OFFER_DIE_SCENE.instantiate()
		_shop_dice_row.add_child(card)
		card.configure(catalog.get_dice(dice_id), dice_id, true)
		card.mouse_entered.connect(_on_offer_hovered.bind(card))
		card.mouse_exited.connect(_on_dice_hover_exited)
		_offer_cards.append(card)


func _rebuild_pool(roster: RefCounted) -> void:
	# 코드가 만든 칸만 지운다. %PoolGrid에 장식 노드를 두어도 유지된다.
	for existing_cell in _pool_cells:
		if is_instance_valid(existing_cell):
			existing_cell.queue_free()
	_pool_cells.clear()

	var catalog = CatalogService.shared()
	var owned: Array = roster.get_owned_dice()

	for cell in POOL_CELLS:
		var pool_cell: Control = SHOP_POOL_CELL_SCENE.instantiate()
		pool_cell.set_cell_index(cell)
		_pool_grid.add_child(pool_cell)
		pool_cell.offer_dropped.connect(_on_offer_dropped)
		pool_cell.cell_clicked.connect(_on_cell_clicked)
		pool_cell.cell_hovered.connect(_on_cell_hovered.bind(pool_cell))
		pool_cell.cell_unhovered.connect(_on_dice_hover_exited)
		_pool_cells.append(pool_cell)

		if _pending.has(cell):
			var pending_res: Resource = catalog.get_dice(str(_pending[cell]))
			pool_cell.show_die(pending_res, pool_cell.State.PENDING)
		elif cell < owned.size():
			pool_cell.show_die(owned[cell], pool_cell.State.OWNED)
		else:
			pool_cell.show_empty()


func _on_offer_dropped(cell_index: int, dice_id: String) -> void:
	if dice_id.is_empty():
		return
	# 빈 칸에 새로 넣는 경우, 이미 대기 중인 추가분까지 합쳐 최대 보유 수를 넘지 않게 막는다.
	if cell_index >= _owned_count and not _pending.has(cell_index):
		if _projected_owned_count() >= POOL_CELLS:
			return
	_pending[cell_index] = dice_id
	_rebuild_pool(RunManager.get_dice_roster())
	_emit_pending_changed()


func _on_cell_clicked(cell_index: int) -> void:
	if not _pending.has(cell_index):
		return
	_pending.erase(cell_index)
	_rebuild_pool(RunManager.get_dice_roster())
	_emit_pending_changed()


func _projected_owned_count() -> int:
	var adds := 0
	for cell in _pending:
		if cell >= _owned_count:
			adds += 1
	return _owned_count + adds


func _on_offer_hovered(card: Control) -> void:
	var resource: Resource = card.get_resource()
	if resource != null:
		_show_hover_for_resource(card, resource)


func _on_cell_hovered(_cell_index: int, resource: Resource, cell: Control) -> void:
	if resource != null:
		_show_hover_for_resource(cell, resource)


func _show_hover_for_resource(anchor: Control, resource: Resource) -> void:
	if _hover_presenter == null or not _hover_presenter.has_method("show_die_faces"):
		return
	var faces: Array[Resource] = resource.get_faces()
	if faces.is_empty():
		return
	_hover_presenter.set_active(true)
	_hover_presenter.show_die_faces(anchor, faces, faces, -1)


func _on_dice_hover_exited() -> void:
	if _hover_presenter != null and _hover_presenter.has_method("hide_preview"):
		_hover_presenter.hide_preview()


func _emit_pending_changed() -> void:
	pending_changed.emit(get_pending_count(), get_pending_cost())
