class_name VisitorController
extends Node2D

const Economy = preload("res://scripts/core/tour_economy.gd")
const Services = preload("res://scripts/core/tour_services.gd")
var gate: Vector2i:
	get:
		return Vector2i(int(world.ground.gate[0]), int(world.ground.gate[1]))
const STEP := 0.1

enum State { ENTERING, CHOOSING_SERVICE, MOVING_TO_SERVICE, QUEUING, USING_SERVICE, FINISHING_SERVICE, LEAVING, EXITED }

var world: WorldManager
var paths: PathfindingManager
var boats: BoatController
var economy := Economy.new()
var services := Services.new()
var types: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/visitor_types.json"))
var guests: Array[Dictionary] = []
var events: Array[String] = []
var reports := {}
var selected := {}
var debug := false
var redraw_pending := false
var speed := 1
var elapsed := 0.0
var accumulator := 0.0
var next_spawn := 0.0
var next_payroll := 60.0
var serial := 0
var reputation := 72.0
var server_economy := false
var dock_market := {}
var used_dock_period := -1

var access_cache := {}
var textures := [
	preload("res://assets/characters/character_tourist_male_idle.png"),
	preload("res://assets/characters/character_tourist_female_idle.png"),
	preload("res://assets/characters/character_tourist_backpacker_idle.png")
]
var peak_step_ms := 0.0
var skipped_steps := 0
const MAX_STEPS_PER_FRAME := 4

func receive_dock_market(market: Dictionary) -> void:
	dock_market = market

func _process(delta: float) -> void:
	accumulator += delta * speed
	var budget := STEP * MAX_STEPS_PER_FRAME
	if accumulator > budget:
		skipped_steps += int(ceil((accumulator - budget) / STEP))
		accumulator = budget
	if accumulator >= STEP:
		var started := Time.get_ticks_usec()
		while accumulator + 0.000001 >= STEP:
			accumulator = maxf(0.0, accumulator - STEP)
			tick(STEP)
		peak_step_ms = maxf(peak_step_ms, (Time.get_ticks_usec() - started) / 1000.0)
	var blend := clampf(accumulator / STEP, 0.0, 1.0)
	for guest in guests:
		if guest.sprite.visible:
			var previous: Vector2 = guest.previous_position
			guest.sprite.position = previous.lerp(guest.position, blend)
	boats.render(services.instances, blend * STEP)
	if debug or redraw_pending:
		redraw_pending = debug
		queue_redraw()

func report(day: int) -> Dictionary:
	if not reports.has(day):
		reports[day] = {"arrived":0, "left":0, "served":0, "abandoned":0, "rating":0.0}
	return reports[day]

func day() -> int:
	return int(elapsed / Economy.DAY_LENGTH)

func log_event(message: String) -> void:
	events.push_front(message)
	if events.size() > 30:
		events.pop_back()

func tick(delta: float) -> void:
	elapsed += delta
	if not server_economy and elapsed >= next_payroll:
		next_payroll += 60.0
		for service: Dictionary in services.instances.values():
			var wage: int = service.staff * Economy.WAGE
			if economy.cash >= wage:
				economy.record("Lương", -wage, service.id, 0, elapsed)
			else:
				service.staff = 0
				log_event("Tạm ngừng nhận khách vì thiếu tiền lương")
	if guests.size() < 35 and elapsed >= next_spawn and paths.walkable(gate):
		spawn()
		var minute := fmod(elapsed, Economy.DAY_LENGTH)
		next_spawn = elapsed + (1.3 if minute < 9 else (3.5 if minute > 180 and minute < 330 else 6.0))
	for service: Dictionary in services.instances.values():
		update_service(service, delta)
	for index in range(guests.size() - 1, -1, -1):
		var guest := guests[index]
		guest.previous_position = guest.position
		advance(guest, delta)
		if guest.state == State.EXITED:
			review(guest)
			guest.sprite.queue_free()
			guests.remove_at(index)
	paths.buildings.visitor_cells.clear()
	for guest in guests:
		paths.buildings.visitor_cells[guest.cell] = true
		if not guest.route.is_empty():
			paths.buildings.visitor_cells[guest.route[0]] = true

func spawn() -> void:
	var profile: Dictionary = types[serial % types.size()]
	var sprite := Sprite2D.new()
	sprite.texture = textures[serial % textures.size()]
	sprite.scale = Vector2.ONE * 0.17
	sprite.offset.y = -108
	sprite.position = world.cell_center(gate)
	world.objects.add_child(sprite)
	serial += 1
	guests.append({"id":serial, "profile":profile.name, "party":int(profile.party),
		"budget":int(profile.budget), "money":int(profile.budget), "time":float(profile.time),
		"hunger":float(profile.hunger), "energy":90.0, "patience":float(profile.patience),
		"satisfaction":65.0, "target":0, "state":State.ENTERING, "cell":gate, "route":[],
		"sprite":sprite, "position":sprite.position, "previous_position":sprite.position, "wait":0.0, "history":[], "avoid":{}, "reason":"Vừa tới cổng"})
	report(day()).arrived += int(profile.party)

func invalidate() -> void:
	paths.invalidate()
	access_cache.clear()
	services.sync(paths.buildings)
	for guest in guests:
		if guest.target != 0 and not services.instances.has(guest.target):
			guest.target = 0
			guest.sprite.show()
			guest.satisfaction -= 8
			guest.reason = "Dịch vụ đã đóng"
			guest.state = State.CHOOSING_SERVICE
		if guest.state in [State.MOVING_TO_SERVICE, State.LEAVING]:
			guest.position = world.cell_center(guest.cell)
			guest.previous_position = guest.position
			guest.route.clear()
			if guest.state == State.LEAVING:
				leave(guest)
			else:
				guest.state = State.CHOOSING_SERVICE

func access_route(guest: Dictionary, service: Dictionary) -> Dictionary:
	var start: Vector2i = guest.cell
	var id: int = service.id
	if not access_cache.has(id):
		access_cache[id] = {}
	var by_start: Dictionary = access_cache[id]
	if by_start.has(start):
		return by_start[start]
	var reachable := paths.reachable_from(start)
	var building: Dictionary = service.building
	if server_economy and world.ground.entrances.has(service.kind):
		var point: Array = world.ground.entrances[service.kind]
		var entrance := Vector2i(int(point[0]), int(point[1]))
		var result := {"route":paths.route(start, entrance)} if reachable.has(entrance) else {}
		by_start[start] = result
		return result
	var size := Vector2(paths.buildings.dimensions(building.def))
	var center := Vector2(building.cell) + (size - Vector2.ONE) / 2.0
	var best := {}
	var best_distance := INF
	for offset_y in range(-5, int(size.y) + 5):
		for offset_x in range(-5, int(size.x) + 5):
			var cell: Vector2i = building.cell + Vector2i(offset_x, offset_y)
			var distance := center.distance_squared_to(Vector2(cell))
			if distance >= best_distance or not reachable.has(cell):
				continue
			best = {"cell":cell}
			best_distance = distance
	if not best.is_empty():
		best = {"route":paths.route(start, best.cell)}
	by_start[start] = best
	return best

func price(service: Dictionary, guest: Dictionary) -> int:
	return int(service.price) * (1 if service.kind == "homestay" else int(guest.party))

func desire(guest: Dictionary, kind: String) -> float:
	match kind:
		"ticket":
			return 100.0 if not guest.history.has("dock") else 0.0
		"dock":
			return 115.0 if guest.history.has("ticket") else 0.0
		"restaurant":
			return guest.hunger * 1.5 if guest.hunger >= 42.0 else 0.0
		"homestay":
			return 88.0 if guest.profile == "Nghỉ dưỡng" and (guest.history.has("dock") or guest.energy < 73.0) else 0.0
	return 0.0

func choose(guest: Dictionary) -> void:
	var best_score := 0.0
	var best := {}
	for service: Dictionary in services.instances.values():
		var kind: String = service.kind
		var need := desire(guest, kind)
		var seats: int = 1 if kind in ["ticket","homestay"] else guest.party
		if need <= 0 or guest.history.has(kind) or guest.avoid.has(service.id):
			continue
		if services.capacity(service) < seats or guest.money < price(service, guest) or guest.time < service.spec.duration:
			continue
		var path := access_route(guest, service)
		if path.is_empty():
			continue
		var score := need - float(service.price) / float(service.spec.price) * 20.0
		score -= path.route.size() * 1.2 + services.load_at(service) * 3.0
		if score > best_score:
			best_score = score
			best = {"id":service.id, "route":path.route, "name":service.building.def.name}
	if best.is_empty():
		leave(guest)
		return
	guest.target = best.id
	guest.route = best.route.duplicate()
	guest.reason = "Chọn " + best.name
	guest.state = State.MOVING_TO_SERVICE

func leave(guest: Dictionary) -> void:
	guest.target = 0
	guest.route = paths.route(guest.cell, gate)
	if not guest.history.has("dock") and guest.state != State.LEAVING:
		guest.satisfaction -= 14
		guest.reason = "Rời đi khi chưa tham quan"
	guest.state = State.LEAVING

func advance(guest: Dictionary, delta: float) -> void:
	guest.time -= delta
	guest.hunger = minf(100.0, guest.hunger + delta * 0.24)
	guest.energy = maxf(0.0, guest.energy - delta * 0.24)
	match guest.state:
		State.ENTERING, State.FINISHING_SERVICE:
			guest.state = State.CHOOSING_SERVICE
		State.CHOOSING_SERVICE:
			if guest.time <= 0:
				leave(guest)
			else:
				choose(guest)
		State.MOVING_TO_SERVICE, State.LEAVING:
			if not guest.route.is_empty():
				var next: Vector2i = guest.route[0]
				var target := world.cell_center(next)
				guest.position = Vector2(guest.position).move_toward(target, 105.0 * delta)
				if guest.position == target:
					guest.cell = next
					guest.route.pop_front()
			elif guest.state == State.LEAVING:
				if guest.cell != gate:
					guest.reason = "Lối về bị chặn"
					guest.satisfaction -= 10
				guest.state = State.EXITED
			else:
				var service: Dictionary = services.instances[guest.target]
				if service.queue.size() >= int(service.spec.queue):
					abandon(guest, service, "Hàng đã đầy")
				else:
					service.queue.append(guest)
					guest.wait = 0.0
					guest.state = State.QUEUING
		State.QUEUING:
			var service: Dictionary = services.instances[guest.target]
			guest.wait += delta
			var slot: int = service.queue.find(guest)
			var center := world.cell_center(guest.cell)
			guest.position = center + Vector2((slot % 4 - 1) * 11, (slot / 4) * 8)
			if guest.wait >= guest.patience or guest.time <= 0 or services.capacity(service) == 0:
				abandon(guest, service, "Bỏ hàng chờ")

func abandon(guest: Dictionary, service: Dictionary, reason: String) -> void:
	service.queue.erase(guest)
	guest.position = world.cell_center(guest.cell)
	guest.previous_position = guest.position
	guest.avoid[service.id] = true
	guest.satisfaction -= 12
	guest.reason = reason
	guest.state = State.CHOOSING_SERVICE
	report(day()).abandoned += guest.party
	log_event("#%d · %s · %s" % [guest.id, reason, service.building.def.name])

func update_service(service: Dictionary, delta: float) -> void:
	var dock: bool = service.kind == "dock"
	if dock and service.remaining > 0:
		service.remaining = maxf(0.0, service.remaining - delta)
	for index in range(service.groups.size() - 1, -1, -1):
		var job: Dictionary = service.groups[index]
		job.remaining -= delta
		if job.remaining <= 0:
			finish(job.guest, service)
			service.groups.remove_at(index)
			if dock and service.groups.is_empty():
				log_event("Thuyền trở về bến")
	if dock and service.remaining > 0:
		return
	var available := services.capacity(service)
	var synced := dock and server_economy
	if synced:
		var period := int(dock_market.get("period", -1))
		if period <= used_dock_period or dock_market.is_empty():
			return
		available = mini(available, int(dock_market.get("dockSeats", 0)))
	for job: Dictionary in service.groups:
		available -= int(job.party)
	while available > 0 and not service.queue.is_empty():
		var guest: Dictionary = service.queue[0]
		var seats: int = 1 if service.kind in ["ticket", "homestay"] else guest.party
		var charge := price(service, guest)
		if charge > guest.money or guest.time < service.spec.duration or seats > services.capacity(service):
			abandon(guest, service, "Giá, thời gian hoặc sức chứa không phù hợp")
			continue
		if seats > available:
			break
		service.queue.pop_front()
		available -= seats
		guest.money -= charge
		guest.satisfaction -= guest.wait * 0.35 + maxf(0.0, float(service.price) / float(service.spec.price) - 1.0) * 16.0
		guest.state = State.USING_SERVICE
		guest.sprite.hide()
		var duration := float(service.spec.duration)
		service.groups.append({"guest":guest, "party":seats, "remaining":duration})
		if not server_economy:
			economy.record(service.kind, charge, service.id, guest.id, elapsed)
			economy.record("Chi phí dịch vụ", -int(service.spec.cost) * seats, service.id, guest.id, elapsed)
		log_event("#%d · %s · +%dk" % [guest.id, service.building.def.name, charge])
		if dock and service.remaining <= 0:
			if synced:
				used_dock_period = int(dock_market.period)
			service.remaining = duration
			log_event("Thuyền khởi hành · Chuyến %d" % guest.id)

func finish(guest: Dictionary, service: Dictionary) -> void:
	guest.history.append(service.kind)
	guest.satisfaction += float(service.spec.quality)
	guest.reason = "Hoàn tất " + service.building.def.name
	match service.kind:
		"dock":
			guest.energy -= 20
		"restaurant":
			guest.hunger = 0.0
		"homestay":
			guest.energy = 100.0
	guest.position = world.cell_center(guest.cell)
	guest.previous_position = guest.position
	guest.sprite.show()
	guest.state = State.FINISHING_SERVICE
	log_event("#%d · %s" % [guest.id, guest.reason])

func review(guest: Dictionary) -> void:
	var rating := clampf(guest.satisfaction, 0.0, 100.0)
	reputation = lerpf(reputation, rating, 0.07)
	var daily := report(day())
	daily.left += guest.party
	daily.rating += rating * guest.party
	if not guest.history.is_empty():
		daily.served += guest.party
	log_event("#%d · Rời đi · %.0f%% · %s" % [guest.id, rating, guest.reason])

func _draw() -> void:
	if not debug:
		return
	var font := ThemeDB.fallback_font
	for service: Dictionary in services.instances.values():
		var anchor: Vector2 = service.building.sprite.position
		draw_string(font, anchor + Vector2(-48, 14), "Chờ %d · %d/%d" % [
			service.queue.size(), services.busy(service), services.capacity(service)], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.GOLD)
	for guest in guests:
		if guest.sprite.visible:
			draw_string(font, guest.sprite.position + Vector2(-12, -51),
				"#%d %s" % [guest.id, State.keys()[guest.state]], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.PALE_GREEN)
	if selected.is_empty() or selected.state == State.EXITED:
		return
	var start: Vector2 = selected.sprite.position
	for cell: Vector2i in selected.route:
		var target := world.cell_center(cell)
		draw_line(start, target, Color.GOLD, 4.0, true)
		start = target

