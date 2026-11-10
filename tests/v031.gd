extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, name: String) -> void:
	if condition:
		print("PASS ", name)
	else:
		failures.append(name)
		printerr("FAIL ", name)

func run() -> void:
	var app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	app.visitors.set_process(false)
	app.camera.set_process(false)
	var saved_cap := Engine.max_fps
	for index in range(3):
		app.ui.apply_fps(index, false)
		check(Engine.max_fps == [60,80,100][index], "Applied cap %d" % [60,80,100][index])
	Engine.max_fps = saved_cap
	var sim: VisitorController = app.visitors
	sim.tick(0.1)
	var guest: Dictionary = sim.guests[0]
	var from: Vector2 = guest.position
	guest.previous_position = from
	guest.position = from + Vector2(10,0)
	sim.accumulator = 0.0
	sim._process(0.05)
	check(guest.sprite.position.is_equal_approx(from + Vector2(5,0)), "Visitor interpolates halfway without changing simulation position")
	check(guest.position.is_equal_approx(from + Vector2(10,0)), "Simulation coordinates independent of render")
	var camera: CameraController = app.camera
	var start := camera.goal
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.position = Vector2(450,350)
	touch.pressed = true
	camera.handle_touch(touch)
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = Vector2(480,350)
	camera.handle_touch(drag)
	check(camera.goal.x < start.x, "Single touch pans map")
	var second := InputEventScreenTouch.new()
	second.index = 1
	second.position = Vector2(560,350)
	second.pressed = true
	camera.handle_touch(second)
	var zoom_before := camera.zoom_goal
	drag.position = Vector2(460,350)
	camera.handle_touch(drag)
	check(camera.zoom_goal > zoom_before, "Pinch distance increases zoom")
	touch.pressed = false
	second.pressed = false
	camera.handle_touch(touch)
	camera.handle_touch(second)
	await process_frame
	var settings: Button
	for button in app.ui.root.find_children("*", "Button", true, false):
		if button.text == "Cài đặt":
			settings = button
			break
	var tap := InputEventScreenTouch.new()
	tap.position = settings.get_global_rect().get_center()
	tap.pressed = true
	camera.handle_touch(tap)
	tap.pressed = false
	camera.handle_touch(tap)
	await process_frame
	check(app.ui.settings_panel.visible, "Touch tap activates a HUD control")
	if app.ui.properties != null:
		app.ui.properties.active = false
		var dock: Dictionary
		for service: Dictionary in sim.services.instances.values():
			if service.kind == "dock":
				dock = service
		dock.building["facility"] = {"id":"dock"}
		guest.money = 500
		guest.time = 200
		guest.state = VisitorController.State.QUEUING
		dock.queue.append(guest)
		sim.receive_dock_market({"period":1,"dockSeats":0})
		sim.update_service(dock, 0.1)
		check(dock.groups.is_empty(), "Server allocation zero prevents boarding")
		sim.receive_dock_market({"period":2,"dockSeats":3})
		sim.update_service(dock, 0.1)
		check(dock.groups.size() == 1 and sim.used_dock_period == 2, "Server allocation admits one trip and is consumed")
		dock.remaining = 0
		dock.groups.clear()
		dock.queue.append(guest)
		sim.update_service(dock, 0.1)
		check(dock.groups.is_empty(), "Market period cannot be reused")
	print("V031: ", "PASS" if failures.is_empty() else failures)
	quit(int(not failures.is_empty()))

