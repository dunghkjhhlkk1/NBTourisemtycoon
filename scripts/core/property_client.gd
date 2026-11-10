extends Node2D

var buildings: BuildingManager
var world: WorldManager
var district
var api: HTTPRequest
var base := "http://localhost:8766"
var token := ""
var state := {}
var busy := false
var delay := 0.0
var plot_id := ""
var active := true
var message := "Đang kết nối máy chủ…"
var by_facility := {}
var by_asset := {}
var mobile_code := ""
var denied := false

func _ready() -> void:
	if OS.has_feature("web"):
		var window := JavaScriptBridge.get_interface("window")
		base = str(window.location.origin)
		if base.begins_with("https://"):
			var fragment := str(window.location.hash)
			if fragment.begins_with("#code="):
				mobile_code = fragment.substr(6).uri_decode()
				window.sessionStorage.setItem("tourism-mobile-code", mobile_code)
				window.history.replaceState(null, "", str(window.location.pathname))
			else:
				var saved: Variant = window.sessionStorage.getItem("tourism-mobile-code")
				if saved is String:
					mobile_code = saved
	api = HTTPRequest.new()
	api.timeout = 8
	add_child(api)

func _process(delta: float) -> void:
	if not active or busy:
		return
	delay -= delta
	if delay <= 0:
		refresh()

func request(path: String, method := HTTPClient.METHOD_GET, body := "") -> Array:
	var headers := PackedStringArray(["Content-Type: application/json"])
	if path == "/api/session" and not mobile_code.is_empty():
		headers.append("X-Mobile-Code: " + mobile_code)
	if not token.is_empty():
		headers.append("Authorization: Bearer " + token)
	var result := api.request(base + path, headers, method, body)
	if result != OK:
		return [0, {}]
	var reply: Array = await api.request_completed
	var parsed: Variant = JSON.parse_string(reply[3].get_string_from_utf8())
	return [reply[1], parsed if parsed is Dictionary else {}]

func refresh() -> void:
	busy = true
	if token.is_empty():
		var session := await request("/api/session")
		token = session[1].get("token", "")
		denied = session[0] == 403
		if denied and OS.has_feature("web") and base.begins_with("https://"):
			JavaScriptBridge.get_interface("window").tourismRequestMobileCode()
	var reply := await request("/api/state") if not token.is_empty() else [0, {}]
	if reply[0] == 200:
		state = reply[1]
		sync_facilities()
		get_parent().visitors.receive_dock_market(state.get("market", {}))
		if message in ["Đang kết nối máy chủ…", "Mất kết nối máy chủ"]:
			message = "Đã đồng bộ doanh nghiệp"
	else:
		token = ""
		message = "Cần mã truy cập HTTPS cho điện thoại" if denied else "Mất kết nối máy chủ"
	delay = 10.0 if denied else 2.0
	busy = false
	queue_redraw()

func sync_facilities() -> void:
	by_asset.clear()
	for asset: Dictionary in state.assets:
		by_asset[asset.id] = asset
	for facility: Dictionary in state.facilities:
		var record: Dictionary = by_facility.get(facility.id, {})
		if record.is_empty():
			var cell := Vector2i(int(facility.x), int(facility.y))
			for existing in buildings.placed:
				if existing.cell == cell and existing.def.id == facility.kind:
					record = existing
					break
			if record.is_empty():
				record = buildings.place(facility.kind, cell, true)
			if record.is_empty():
				continue
			by_facility[facility.id] = record
			if district != null:
				var sprite: Sprite2D = record.sprite
				var label: String = by_asset[facility.assetId].name
				if by_asset[facility.assetId].kind.ends_with("Plot"):
					label = buildings.definitions[facility.kind].name
				district.add_sign(label.replace(" · NPC", ""), sprite.position + Vector2(0,-sprite.get_rect().size.y * sprite.scale.y * 0.76), Color("#3c2b19"))
		record["facility"] = facility
		var simulation: VisitorController = get_parent().visitors
		var service: Dictionary = simulation.services.instances.get(record.sprite.get_instance_id(), {})
		if not service.is_empty():
			service.price = int(facility.price)
			service.staff = int(facility.staff) if facility.open else 0
			if facility.owner != "npc" and not can_manage(facility.assetId):
				service.staff = 0

func lease(asset_id: String) -> Dictionary:
	for contract: Dictionary in state.get("leases", []):
		if contract.assetId == asset_id and contract.status == "Active" and contract.end > state.period:
			return contract
	return {}

func can_manage(asset_id: String) -> bool:
	var contract := lease(asset_id)
	return not contract.is_empty() and contract.paidThrough > state.period

func command(action: String, target: String, kind := "", cell := Vector2i.ZERO, value := 0) -> bool:
	if busy or token.is_empty():
		message = "Chờ máy chủ đồng bộ rồi thử lại."
		return false
	var random := Crypto.new().generate_random_bytes(16).hex_encode()
	var id := "%s-%s-%s-%s-%s" % [random.substr(0,8), random.substr(8,4), random.substr(12,4), random.substr(16,4), random.substr(20)]
	var body := JSON.stringify({"key":id, "action":action, "target":target, "kind":kind, "x":cell.x, "y":cell.y, "value":value})
	busy = true
	var reply := await request("/api/actions", HTTPClient.METHOD_POST, body)
	if reply[0] == 0:
		reply = await request("/api/actions", HTTPClient.METHOD_POST, body)
	var success: bool = reply[0] == 200
	message = "Đã lưu trên máy chủ" if success else str(reply[1].get("message", "Thao tác chưa được xác nhận"))
	await refresh()
	return success

func contains(asset: Dictionary, cell: Vector2i, size: Vector2i) -> bool:
	var boundary := Rect2i(int(asset.x), int(asset.y), int(asset.width), int(asset.height))
	return boundary.encloses(Rect2i(cell, size))

func permits(kind: String, cell: Vector2i) -> bool:
	var asset: Dictionary = by_asset.get(plot_id, {})
	if asset.is_empty() or not can_manage(plot_id) or not asset.allowed.split(",").has(kind):
		return false
	var size := buildings.dimensions(buildings.definitions[kind])
	if not contains(asset, cell, size):
		return false
	for footprint in buildings.cells(buildings.definitions[kind], cell):
		if world.road_cells.has(footprint):
			return false
	return true

func select_plot(cell: Vector2i) -> bool:
	for asset: Dictionary in by_asset.values():
		if asset.kind.ends_with("Plot") and contains(asset, cell, Vector2i.ONE):
			plot_id = asset.id
			queue_redraw()
			return true
	return false

func _draw() -> void:
	for asset: Dictionary in by_asset.values():
		if not asset.kind.ends_with("Plot"):
			continue
		var origin := Vector2(asset.x, asset.y)
		var size := Vector2(asset.width, asset.height)
		var line := Color("#e0bb6c") if asset.id == plot_id else (Color("#79c69c") if can_manage(asset.id) else Color("#dce5a089"))
		if asset.kind == "ProtectedPlot":
			line = Color("#9cc8e49e")
		var outline := PackedVector2Array([world.project(origin), world.project(origin + Vector2(size.x,0)),
			world.project(origin + size), world.project(origin + Vector2(0,size.y)), world.project(origin)])
		draw_polyline(outline, line, 3.0, true)
		draw_string(ThemeDB.fallback_font, world.project(origin) + Vector2(5,-5), asset.name,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 17, line)

