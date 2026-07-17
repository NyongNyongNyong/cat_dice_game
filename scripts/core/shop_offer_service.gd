extends RefCounted

const OFFERS_PATH := "res://data/economy/shop_offers.json"

static var _shared = null


static func shared():
	if _shared == null:
		var script: GDScript = load("res://scripts/core/shop_offer_service.gd") as GDScript
		_shared = script.new()
		_shared.reload()
	return _shared


static func reset_for_tests() -> void:
	_shared = null


func reload() -> void:
	_offers = _load_offers()


var _offers: Array[Dictionary] = []


func get_offers() -> Array[Dictionary]:
	return _offers.duplicate(true)


func get_offer(dice_id: String) -> Dictionary:
	for offer in _offers:
		if str(offer.get("dice_id", "")) == dice_id:
			return offer.duplicate(true)
	return {}


func get_price(dice_id: String) -> int:
	var offer := get_offer(dice_id)
	return int(offer.get("price_gold", 0))


func _load_offers() -> Array[Dictionary]:
	var text := FileAccess.get_file_as_string(OFFERS_PATH)
	if text.is_empty():
		push_error("ShopOfferService: failed to read %s" % OFFERS_PATH)
		return _fallback_offers()

	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		push_error("ShopOfferService: invalid JSON in %s" % OFFERS_PATH)
		return _fallback_offers()

	var loaded: Array[Dictionary] = []
	for entry in data.get("offers", []):
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var dice_id: String = str(entry.get("dice_id", ""))
		if dice_id.is_empty():
			continue
		loaded.append({
			"dice_id": dice_id,
			"price_gold": maxi(int(entry.get("price_gold", 0)), 0),
		})

	if loaded.is_empty():
		return _fallback_offers()
	return loaded


func _fallback_offers() -> Array[Dictionary]:
	return [
		{"dice_id": "dice_triple_h", "price_gold": 2},
		{"dice_id": "dice_triple_l", "price_gold": 2},
		{"dice_id": "dice_triple_v", "price_gold": 3},
	]
