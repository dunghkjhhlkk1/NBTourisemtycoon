extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var app: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	var sim: VisitorController = app.visitors
	sim.set_process(false)
	var failures: Array[String] = []
	var paid := {}
	var service_kinds := {}
	var initial_cash := sim.economy.cash
	var seen_guests := {}
	var cursor := 0
	var queued := false
	var dock: Dictionary
	for service: Dictionary in sim.services.instances.values():
		if service.kind == "dock":
			dock = service
	for frame in range(6200):
		sim.tick(0.1)
		var memberships := {}
		for service: Dictionary in sim.services.instances.values():
			if sim.services.busy(service) > sim.services.capacity(service):
				failures.append("Capacity exceeded")
			for job: Dictionary in service.groups:
				var guest: Dictionary = job.guest
				if memberships.has(guest.id) or guest.state != VisitorController.State.USING_SERVICE:
					failures.append("Concurrent or invalid service")
				memberships[guest.id] = true
			if service.kind == "dock" and not service.queue.is_empty():
				queued = true
		for guest in sim.guests:
			seen_guests[guest.id] = guest.budget
			if guest.money < 0:
				failures.append("Negative visitor wallet")
		while cursor < sim.economy.entries.size():
			var entry: Dictionary = sim.economy.entries[cursor]
			cursor += 1
			if entry.id != cursor:
				failures.append("Incorrect transaction ID")
			if entry.amount > 0:
				var key := "%d/%s" % [entry.guest, entry.kind]
				if paid.has(key):
					failures.append("Duplicate purchase " + key)
				if entry.kind == "dock" and not paid.has("%d/ticket" % entry.guest):
					failures.append("Boat purchase without ticket")
				paid[key] = true
				service_kinds[entry.kind] = service_kinds.get(entry.kind, 0) + 1
	var first_day := sim.report(0)
	print("Sales: ", service_kinds, " Day one: ", first_day)
	if service_kinds.size() != 4 or not queued or first_day.left == 0 or first_day.abandoned == 0 or sim.day() != 1:
		failures.append("Demo did not exercise the full cycle")
	var ledger_balance := initial_cash
	for entry in sim.economy.entries:
		ledger_balance += int(entry.amount)
	if ledger_balance != sim.economy.cash:
		failures.append("Ledger does not reconcile")
	dock.staff = 0
	if sim.services.capacity(dock) != 0:
		failures.append("Unstaffed dock still accepting guests")
	dock.staff = 1
	if sim.services.capacity(dock) != 3:
		failures.append("Staff did not restore capacity")
	var first: Node2D = load("res://scenes/main.tscn").instantiate()
	var second: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(first)
	root.add_child(second)
	first.visitors.set_process(false)
	second.visitors.set_process(false)
	second.visitors.speed = 4
	for frame in range(1000):
		first.visitors._process(0.1)
		if frame % 4 == 0:
			second.visitors._process(0.1)
	if first.visitors.economy.cash != second.visitors.economy.cash or first.visitors.serial != second.visitors.serial:
		failures.append("Different simulation result at x4")
	if second.visitors.economy.cash == initial_cash or first.visitors.reports.is_empty():
		failures.append("Simulation did not advance")
	var fresh: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(fresh)
	if fresh.visitors.economy.cash != initial_cash or not fresh.visitors.guests.is_empty():
		failures.append("Fresh demo state did not reset")
	print("TOURISM: ", "PASS" if failures.is_empty() else failures)
	quit(int(not failures.is_empty()))

