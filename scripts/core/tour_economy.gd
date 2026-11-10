extends RefCounted

const STARTING_CASH := 12500
const WAGE := 20
const DAY_LENGTH := 600.0

var cash := STARTING_CASH
var entries: Array[Dictionary] = []
var daily := {}
var revenue := {}

func record(kind: String, amount: int, service: int, guest: int, now: float) -> void:
	if amount == 0:
		return
	var day := int(now / DAY_LENGTH)
	var totals: Vector2i = daily.get(day, Vector2i.ZERO)
	if amount > 0:
		totals.x += amount
		var key := Vector2i(day, service)
		revenue[key] = revenue.get(key, 0) + amount
	else:
		totals.y -= amount
	daily[day] = totals
	cash += amount
	entries.append({"id": entries.size() + 1, "kind": kind, "amount": amount,
		"building": service, "guest": guest, "time": now})

