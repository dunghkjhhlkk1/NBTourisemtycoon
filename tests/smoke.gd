extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var app: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	var failures: Array[String] = []
	if app.buildings == null:
		printerr("Main scene did not initialize")
		quit(1)
		return
	check(app.buildings.placed.size() == 5, "Five initial buildings", failures)
	var route: Array[Vector2i] = app.paths.route(Vector2i(11,24), Vector2i(34,28))
	check(not route.is_empty(), "Initial route from gate to scenic point", failures)
	var def: Dictionary = app.buildings.definitions.ticket
	check(not app.buildings.allowed(def, Vector2i(16,21)), "Occupied cells reject overlap", failures)
	check(not app.buildings.allowed(def, Vector2i(34,34)), "Land building rejects water", failures)
	check(not app.buildings.allowed(def, Vector2i(-1,0)), "Out of bounds rejected", failures)
	var dock: Dictionary = app.buildings.definitions.dock
	check(not app.buildings.allowed(dock, Vector2i(9,20)), "Dock requires shoreline", failures)
	check(not app.buildings.allowed(dock, Vector2i(34,34)), "Dock rejects all water", failures)
	app.buildings.select_at(app.buildings.placed[0].sprite.position - Vector2(0,45))
	check(not app.buildings.selected.is_empty(), "Alpha hit testing selects building", failures)
	var record: Dictionary = app.buildings.place("ticket", Vector2i(21,24))
	check(not record.is_empty(), "Valid road construction", failures)
	var alternate: Array[Vector2i] = app.paths.route(Vector2i(11,24), Vector2i(34,28))
	check(not alternate.is_empty() and not alternate.has(Vector2i(21,24)), "Path reroutes around construction", failures)
	var obstruction: Dictionary = app.buildings.place("ticket", Vector2i(20,26))
	check(not obstruction.is_empty(), "Secondary road construction", failures)
	check(app.paths.route(Vector2i(11,24),Vector2i(34,28)).is_empty(), "Full obstruction reports no route", failures)
	app.buildings.select(obstruction)
	app.buildings.remove_selected()
	app.buildings.select(record)
	app.buildings.remove_selected()
	check(app.paths.route(Vector2i(11,24),Vector2i(34,28)) == route, "Deletion restores original path", failures)
	app.builder.begin("ticket")
	check(is_instance_valid(app.builder.preview), "Construction preview created", failures)
	app.builder.cancel()
	check(app.builder.active.is_empty(), "Construction cancels", failures)
	for stop: Vector2 in app.boats.route:
		check(app.world.water_cells.has(app.world.cell_at(stop)), "Boat waypoint is on water", failures)
	app.camera.set_mode(0)
	check(app.camera.zoom_goal < 0.4, "Overview zoom fits map", failures)
	app.camera.set_mode(2)
	check(app.camera.zoom_goal > 1.0, "Close-up zoom", failures)
	await create_timer(6.8).timeout
	check(app.visitors.guests.size() >= 5 and app.visitors.guests.size() <= 10, "Visitors spawn within target count", failures)
	print("SMOKE: %s" % ("PASS" if failures.is_empty() else str(failures)))
	quit(int(not failures.is_empty()))

func check(condition: bool, message: String, failures: Array[String]) -> void:
	if condition:
		print("PASS " + message)
	else:
		failures.append(message)
		printerr("FAIL " + message)
