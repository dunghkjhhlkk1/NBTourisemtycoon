class_name UIManager
extends CanvasLayer

var buildings: BuildingManager
var construction: ConstructionController
var camera: CameraController
var root: Control
var top: Label
var hint: Label
var mode_label: Label
var info: PanelContainer
var info_text: Label
var build_panel: PanelContainer
var menu: PanelContainer
var navigation: VBoxContainer
var navigation_scroll: ScrollContainer
var brand: Label
var hints_panel: PanelContainer
var camera_controls: PanelContainer
var touch_regions: Array[Control] = []
var build_buttons: VBoxContainer
var context_label: Label
var current_panel := ""
var simulation: VisitorController
var properties
var property_panel: PanelContainer
var property_layout: VBoxContainer
var property_text: Label
var property_image: TextureRect
var dock_status: Label
var property_view := ""
var property_target := ""
var property_signature := ""
var monitor: Label
var display_delay := 0.0
var report_mode := false
var performance_badge: Button
var fps_picker: OptionButton
var settings_panel: PanelContainer
var compact_button: Button
var telemetry_panel: PanelContainer
var log_toggle: Button
var compact_layout := false
var compact_menu_open := false
var log_open := true
const FPS_OPTIONS := [60, 80, 100]
const SETTINGS_PATH := "user://tourism_settings.cfg"
var detail_button: Button
var detail_reduced := false
var detailed_fps := false
var sample_time := 0.0
var last_frame_usec := 0
var sample_frames := 0
var worst_frame_ms := 0.0
var speed_buttons: Array[Button] = []
var property_snapshot: Dictionary
var property_message := ""
var property_key := ""

func setup(manager: BuildingManager, builder: ConstructionController, view: CameraController) -> void:
	buildings = manager
	construction = builder
	camera = view
	root = Control.new()
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = make_theme()

	var bar := panel(Vector2(0,0), Vector2(1,0), Rect2(12,12,-24,48))
	top = Label.new()
	var masthead := HBoxContainer.new()
	masthead.add_theme_constant_override("separation", 17)
	bar.add_child(masthead)
	if properties != null:
		brand = Label.new()
		brand.text = "NINH BÌNH TOURISM TYCOON"
		brand.add_theme_color_override("font_color", Color("#f3ca6d"))
		masthead.add_child(brand)
	top.clip_text = true
	top.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	masthead.add_child(top)
	performance_badge = add_button(masthead, "Đang đo FPS", func(): detailed_fps = not detailed_fps)
	performance_badge.tooltip_text = "Bấm để xem khung chậm nhất và thời gian xử lý mô phỏng"
	performance_badge.custom_minimum_size.x = 125
	add_button(masthead, "Cài đặt", func(): settings_panel.visible = not settings_panel.visible)

	menu = panel(Vector2(0,0), Vector2(0,0), Rect2(12,69,132,0))
	navigation = VBoxContainer.new()
	menu.add_child(navigation)
	navigation_scroll = ScrollContainer.new()
	navigation_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	navigation_scroll.hide()
	menu.add_child(navigation_scroll)
	add_button(navigation,"Xây dựng",func(): toggle_context("build"))
	add_button(navigation,"Công trình",func(): toggle_context("buildings"))
	add_button(navigation,"Nhân viên",func(): toggle_context("staff"))
	if properties != null:
		add_button(navigation,"Đất & Cơ sở",func(): show_business("assets"))
		add_button(navigation,"Doanh nghiệp",func(): show_business("company"))
		add_button(navigation,"Thị trường",func(): show_business("market"))
		property_panel = panel(Vector2(1,0), Vector2(1,1), Rect2(-330,69,318,-183))
		property_layout = VBoxContainer.new()
		var scroll := ScrollContainer.new()
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		property_panel.add_child(scroll)
		property_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.add_child(property_layout)
		property_text = Label.new()
		property_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		property_text.custom_minimum_size.x = 262
		property_text.add_theme_color_override("font_color", Color("#fae4a9"))
		property_image = TextureRect.new()
		property_image.custom_minimum_size.y = 104
		property_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		property_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		property_layout.add_child(property_image)
		property_layout.add_child(property_text)
		dock_status = Label.new()
		dock_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		dock_status.add_theme_color_override("font_color", Color("#9bd8be"))
		property_layout.add_child(dock_status)
		dock_status.hide()
		property_panel.hide()
	add_button(navigation,"Báo cáo / Nhật ký",func(): report_mode = not report_mode)
	add_button(navigation,"Đường đi",func(): simulation.debug = not simulation.debug)
	var playback := HBoxContainer.new()
	navigation.add_child(playback)
	for rate in [0,1,2,4]:
		var control := add_button(playback, "II" if rate == 0 else "×%d" % rate, set_speed.bind(rate))
		control.toggle_mode = true
		control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		control.tooltip_text = "Tạm dừng hoạt ảnh" if rate == 0 else "Tốc độ mô phỏng ×%d" % rate
		speed_buttons.append(control)
	set_speed(simulation.speed)
	detail_button = add_button(navigation,"Đồ họa: Đầy đủ",toggle_detail)
	add_button(navigation,"Tải lại bản đồ",func(): get_tree().reload_current_scene())
	telemetry_panel = panel(Vector2(0,1), Vector2(0,1), Rect2(12,-190,390,0))
	monitor = Label.new()
	monitor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	telemetry_panel.add_child(monitor)
	add_button(navigation,"Bản đồ",func(): toggle_context("map"))

	build_panel = panel(Vector2(0,0), Vector2(0,0), Rect2(154,69,196,0))
	var content := VBoxContainer.new()
	build_panel.add_child(content)
	context_label = Label.new()
	context_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	context_label.custom_minimum_size.x = 164
	content.add_child(context_label)
	build_buttons = VBoxContainer.new()
	content.add_child(build_buttons)
	build_panel.hide()

	info = panel(Vector2(1,0), Vector2(1,0), Rect2(-244,69,232,0))
	var info_layout := VBoxContainer.new()
	info.add_child(info_layout)
	info_text = Label.new()
	info_layout.add_child(info_text)
	add_button(info_layout,"Giá +10k",change_price.bind(10))
	add_button(info_layout,"Giá −10k",change_price.bind(-10))
	add_button(info_layout,"Tuyển & phân công",change_staff.bind(1))
	add_button(info_layout,"Giảm nhân viên",change_staff.bind(-1))
	add_button(info_layout,"Xóa công trình",buildings.remove_selected)
	add_button(info_layout,"Đóng",func(): buildings.select({}))
	info.hide()

	camera_controls = panel(Vector2(1,1), Vector2(1,1), Rect2(-480,-62,468,50))
	var zoom_row := HBoxContainer.new()
	camera_controls.add_child(zoom_row)
	for index in range(3):
		add_button(zoom_row,["Toàn cảnh","Quản lý","Chi tiết"][index],set_camera_mode.bind(index))
	add_button(zoom_row,"−",camera.shift_zoom.bind(1.0/1.18))
	add_button(zoom_row,"+",camera.shift_zoom.bind(1.18))
	mode_label = Label.new()
	mode_label.text = "Quản lý"
	var mode_panel := panel(Vector2(1,1), Vector2(1,1), Rect2(-144,-107,132,39))
	mode_panel.add_child(mode_label)

	hints_panel = panel(Vector2(0,1), Vector2(0,1), Rect2(12,-62,379,50))
	hint = Label.new()
	hint.clip_text = true
	hints_panel.add_child(hint)
	show_status("")
	buildings.selection_changed.connect(show_selection)
	buildings.changed.connect(refresh_context)
	construction.status_changed.connect(show_status)
	camera.mode_changed.connect(func(title: String): mode_label.text = title)

	compact_button = Button.new()
	compact_button.text = "Menu"
	compact_button.position = Vector2(12, 68)
	compact_button.custom_minimum_size = Vector2(100, 58)
	compact_button.pressed.connect(func():
		compact_menu_open = not compact_menu_open
		update_layout())
	root.add_child(compact_button)
	touch_regions.append(compact_button)
	camera.touch_target = touch_target_at
	log_toggle = add_button(zoom_row, "Nhật ký", func():
		log_open = not log_open
		update_layout())
	setup_settings()
	root.resized.connect(update_layout)
	update_layout()

func setup_settings() -> void:
	settings_panel = panel(Vector2(1,0), Vector2(1,0), Rect2(-284,65,272,0))
	var settings := VBoxContainer.new()
	settings_panel.add_child(settings)
	var label := Label.new()
	label.text = "Giới hạn FPS"
	settings.add_child(label)
	fps_picker = OptionButton.new()
	for rate: int in FPS_OPTIONS:
		fps_picker.add_item("%d FPS" % rate)
	settings.add_child(fps_picker)
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	var selected := FPS_OPTIONS.find(int(config.get_value("display", "fps_limit", 80)))
	apply_fps(1 if selected < 0 else selected, false)
	fps_picker.item_selected.connect(func(index: int): apply_fps(index, true))
	add_button(settings, "Đóng", func(): settings_panel.hide())
	settings_panel.hide()

func apply_fps(index: int, persist: bool) -> void:
	Engine.max_fps = FPS_OPTIONS[index]
	fps_picker.select(index)
	if persist:
		var config := ConfigFile.new()
		config.set_value("display", "fps_limit", Engine.max_fps)
		if config.save(SETTINGS_PATH) != OK:
			show_status("Không lưu được cài đặt FPS.")

func update_layout() -> void:
	compact_layout = OS.has_feature("mobile") or root.size.x < 1024 or get_window().size.x < 1000
	compact_button.visible = compact_layout
	if brand != null:
		brand.visible = not compact_layout
	hints_panel.visible = not compact_layout and root.size.x >= 850
	root.theme.default_font_size = 21 if compact_layout else 16
	camera_controls.offset_left = -560 if compact_layout else -480
	var destination: Control = navigation_scroll if compact_layout else menu
	if navigation.get_parent() != destination:
		navigation.reparent(destination, false)
	navigation.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	navigation_scroll.visible = compact_layout
	menu.anchor_bottom = 1 if compact_layout else 0
	menu.offset_bottom = -68 if compact_layout else 0
	for button in navigation.find_children("*", "Button", true, false):
		button.custom_minimum_size.y = 53 if compact_layout else 0
	menu.visible = not compact_layout or compact_menu_open
	menu.offset_top = 130 if compact_layout else 69
	telemetry_panel.visible = log_open and not compact_layout
	if compact_layout and log_open:
		telemetry_panel.visible = not compact_menu_open and property_view.is_empty()
		telemetry_panel.offset_right = 355
	else:
		telemetry_panel.offset_right = 402
	if property_panel == null:
		return
	property_panel.anchor_left = 0 if compact_layout else 1
	property_panel.anchor_top = 1 if compact_layout else 0
	property_panel.offset_left = 12 if compact_layout else -330
	property_panel.offset_top = -355 if compact_layout else 69
	property_panel.offset_bottom = -68 if compact_layout else -114

func toggle_context(next: String) -> void:
	if properties != null:
		show_business("")
		if next == "build":
			show_business("assets")
			return
	current_panel = "" if current_panel == next else next
	refresh_context()

func refresh_context() -> void:
	build_panel.visible = not current_panel.is_empty()
	for old in build_buttons.get_children():
		build_buttons.remove_child(old)
		old.queue_free()
	match current_panel:
		"build":
			context_label.text = "Chọn loại công trình"
			for id: String in buildings.definitions:
				add_button(build_buttons,buildings.definitions[id].name,func():
					construction.begin(id)
					current_panel = ""
					refresh_context())
		"buildings":
			context_label.text = "%d công trình trên bản đồ" % buildings.placed.size()
			for record in buildings.placed:
				add_button(build_buttons,record.def.name,func():
					buildings.select(record)
					camera.goal = record.sprite.position)
		"staff":
			context_label.text = "Chọn công trình để tuyển hoặc giảm nhân viên. Phí tuyển 40k."
		"map":
			context_label.text = "Tràng An thử nghiệm\n48 × 48 ô"
			add_button(build_buttons,"Xem toàn cảnh",camera.set_mode.bind(0))

func show_selection(record: Dictionary) -> void:
	if properties != null:
		info.hide()
		if record.has("facility"):
			property_target = record.facility.assetId
			show_business("asset")
		return
	info.visible = not record.is_empty()
	if info.visible:
		info_text.text = "%s\nCấp độ 1 · Đang hoạt động\nSức chứa mẫu: %d khách" % [record.def.name, record.def.capacity]

func show_status(message: String) -> void:
	hint.text = "WASD · Chuột giữa · Cuộn · Home" if message.is_empty() else message

func set_camera_mode(mode: int) -> void:
	camera.set_mode(mode)
	if mode != 2:
		return
	if not buildings.selected.is_empty():
		camera.goal = buildings.selected.sprite.position + Vector2(0, -60)
	elif properties != null and properties.by_asset.has(property_target):
		var asset: Dictionary = properties.by_asset[property_target]
		var center := Vector2(asset.x, asset.y) + Vector2(asset.width, asset.height) * 0.5
		camera.goal = construction.world.project(center) + Vector2(0, -35)

func set_speed(rate: int) -> void:
	simulation.speed = rate
	var rates := [0, 1, 2, 4]
	for index in speed_buttons.size():
		speed_buttons[index].set_pressed_no_signal(rate == rates[index])

func toggle_detail() -> void:
	detail_reduced = not detail_reduced
	detail_button.text = "Đồ họa: Gọn" if detail_reduced else "Đồ họa: Đầy đủ"
	for sprite: CanvasItem in get_tree().get_nodes_in_group("scenery_detail"):
		sprite.visible = not detail_reduced

func sample_performance() -> void:
	var now := Time.get_ticks_usec()
	if last_frame_usec == 0:
		last_frame_usec = now
		return
	var delta := (now - last_frame_usec) / 1000000.0
	last_frame_usec = now
	sample_time += delta
	sample_frames += 1
	worst_frame_ms = maxf(worst_frame_ms, delta * 1000.0)
	if sample_time < 1.0:
		return
	var fps := roundi(sample_frames / sample_time)
	var frame_ms := sample_time * 1000.0 / sample_frames
	performance_badge.text = "%d FPS / %d  ·  %.1f ms" % [fps, Engine.max_fps, frame_ms]
	if detailed_fps:
		performance_badge.text += "  |  Đỉnh %.1f ms  |  Mô phỏng %.1f ms" % [worst_frame_ms, simulation.peak_step_ms]
	performance_badge.modulate = Color("#ffd48a") if fps < 30 else Color.WHITE
	sample_time = 0.0
	sample_frames = 0
	worst_frame_ms = 0.0
	simulation.peak_step_ms = 0.0

func selected_service() -> Dictionary:
	if buildings.selected.is_empty():
		return {}
	return simulation.services.instances.get(buildings.selected.sprite.get_instance_id(), {})

func change_price(amount: int) -> void:
	var service := selected_service()
	if not service.is_empty():
		if properties != null:
			manage_facility("price", int(service.price) + amount)
		else:
			service.price = clampi(service.price + amount, 5, 500)

func change_staff(amount: int) -> void:
	var service := selected_service()
	if service.is_empty():
		return
	if properties != null:
		manage_facility("staff", int(service.staff) + amount)
		return
	if amount < 0 and not service.groups.is_empty():
		show_status("Hãy đợi phục vụ xong trước khi giảm nhân viên.")
		return
	var limit := 1 if service.kind == "dock" else 3
	var next := clampi(service.staff + amount, 0, limit)
	var hiring_cost := 40
	if next > service.staff:
		if simulation.economy.cash < hiring_cost:
			show_status("Không đủ tiền tuyển nhân viên.")
			return
		simulation.economy.record("Tuyển dụng", -hiring_cost, service.id, 0, simulation.elapsed)
	service.staff = next

func _unhandled_input(event: InputEvent) -> void:
	if simulation == null or not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if not construction.active.is_empty():
		return
	simulation.selected = {}
	var point: Vector2 = construction.get_canvas_transform().affine_inverse() * event.position
	for guest in simulation.guests:
		var sprite: Sprite2D = guest.sprite
		if sprite.visible and sprite.get_rect().has_point(sprite.to_local(point)):
			simulation.selected = guest
			buildings.select({})
			get_viewport().set_input_as_handled()
			return
	if properties != null and properties.select_plot(construction.world.cell_at(point)):
		buildings.select({})
		property_target = properties.plot_id
		show_business("asset")
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if monitor == null:
		return
	sample_performance()
	display_delay -= delta
	if display_delay > 0:
		return
	display_delay = 0.2
	var day := simulation.day()
	var minutes := int(fmod(simulation.elapsed, 600.0) * 1.2) + 480
	var totals: Vector2i = simulation.economy.daily.get(day, Vector2i.ZERO)
	var stats := simulation.report(day)
	top.text = "TRÀNG AN V0.2  |  %dk  ·  Ngày %d %02d:%02d  ·  %d nhóm  ·  %d khách đã phục vụ  ·  %.0f%%  ·  Thu %dk / Lãi %dk  ·  ×%d" % [
		simulation.economy.cash, day + 1, minutes / 60, minutes % 60, simulation.guests.size(),
		stats.served, simulation.reputation, totals.x, totals.x - totals.y, simulation.speed]
	if properties != null:
		refresh_business()
		update_dock_status()
		var company: Dictionary = properties.state.get("company", {})
		var amounts: Dictionary = properties.state.get("amounts", {}) if properties.state.get("amounts") != null else {}
		var visitor_count := 0
		for guest in simulation.guests:
			visitor_count += int(guest.party)
		top.text = "TRÀNG AN  V0.4 A    |    Ngày %d  %02d:%02d    |    %s    |    %d khách    |    %.0f%% hài lòng    |    Thu %.0fk / Lãi %.0fk    |    ×%d" % [
			day + 1, minutes / 60, minutes % 60, ("%.0fk" % company.balance if company.has("balance") else "—"),
			visitor_count, simulation.reputation, amounts.get("revenue", 0),
			float(amounts.get("revenue", 0)) - float(amounts.get("expenses", 0)), simulation.speed]
	var service := selected_service()
	if properties == null and not service.is_empty():
		var state := "Mở cửa" if service.staff > 0 else "Thiếu nhân viên"
		info_text.text = "%s · Cấp 1\n%s · Giá %dk\nNhân viên %d · Chờ %d nhóm\nĐang phục vụ %d/%d\nThu hôm nay %dk" % [
			buildings.selected.def.name, state, service.price, service.staff, service.queue.size(),
			simulation.services.busy(service), simulation.services.capacity(service),
			simulation.economy.revenue.get(Vector2i(day, service.id), 0)]
	var guest := simulation.selected
	var lines := PackedStringArray()
	if not guest.is_empty():
		lines.append("#%d · %s · %d người · %s" % [guest.id, guest.profile, guest.party, simulation.State.keys()[guest.state]])
		lines.append("%dk/%dk · Đói %.0f · Sức %.0f · Hài lòng %.0f%%" % [
			guest.money, guest.budget, guest.hunger, guest.energy, clampf(guest.satisfaction, 0, 100)])
		lines.append("%s · Còn %.0fs" % [guest.reason, maxf(0,guest.time)])
	elif report_mode:
		var report_day := maxi(0, day - 1)
		var report := simulation.report(report_day)
		var amounts: Vector2i = simulation.economy.daily.get(report_day, Vector2i.ZERO)
		lines.append("Ngày %d · Đến %d · Rời %d · Bỏ hàng %d" % [report_day+1, report.arrived, report.left, report.abandoned])
		lines.append("Thu %dk · Chi %dk · Lãi %dk · Điểm %.0f%%" % [
			amounts.x, amounts.y, amounts.x-amounts.y, report.rating / maxi(1, report.left)])
	else:
		lines.append("Nhật ký vận hành · Nhấp khách để xem hành trình")
	if properties != null:
		if guest.is_empty():
			lines.clear()
			lines.append("Sổ giao dịch doanh nghiệp · %s" % properties.message)
			var ledger: Array = properties.state.get("ledger", [])
			for index in range(mini(ledger.size(), 3)):
				var entry: Dictionary = ledger[index]
				lines.append("%s · %+.0fk" % [entry.kind, entry.amount])
	else:
		for index in range(mini(simulation.events.size(), 3)):
			lines.append(simulation.events[index])
	monitor.text = "\n".join(lines)

func touch_target_at(point: Vector2) -> Control:
	for index in range(touch_regions.size() - 1, -1, -1):
		var region := touch_regions[index]
		if region.is_visible_in_tree() and region.get_global_rect().has_point(point):
			for child in region.get_children():
				if child is ScrollContainer and child.is_visible_in_tree():
					return child
			return region
	return null

func panel(first: Vector2, last: Vector2, box: Rect2) -> PanelContainer:
	var item := PanelContainer.new()
	root.add_child(item)
	touch_regions.append(item)
	item.anchor_left = first.x
	item.anchor_top = first.y
	item.anchor_right = last.x
	item.anchor_bottom = last.y
	item.offset_left = box.position.x
	item.offset_top = box.position.y
	item.offset_right = box.end.x
	item.offset_bottom = box.end.y
	return item

func add_button(parent: Control, title: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = title
	var icon := menu_icon(title)
	if icon != null:
		button.icon = icon
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.focus_mode = Control.FOCUS_NONE
	parent.add_child(button)
	button.pressed.connect(action)
	return button

func make_theme() -> Theme:
	var result := Theme.new()
	result.default_font_size = 16
	result.set_stylebox("panel","PanelContainer",style(Color("#142b2af5"),Color("#41635e"),12))
	result.set_stylebox("normal","Button",style(Color("#20413d"),Color("#395953"),8))
	result.set_stylebox("hover","Button",style(Color("#2a5650"),Color("#6f9e8a"),8))
	result.set_stylebox("pressed","Button",style(Color("#345f49"),Color("#94ba86"),8))
	result.set_color("font_color","Label",Color("#f3edce"))
	return result

func style(fill: Color, edge: Color, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill

	box.border_color = edge
	box.set_border_width_all(1)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 10
	box.content_margin_right = 10
	box.content_margin_top = 5
	box.content_margin_bottom = 5
	return box

func show_business(view: String) -> void:
	if compact_layout and not view.is_empty():
		compact_menu_open = false
		update_layout()
	property_view = view
	update_layout()
	property_signature = ""
	build_panel.hide()
	refresh_business()

func action(action_name: String, target: String, facility := "", value := 0) -> void:
	await properties.command(action_name, target, facility, Vector2i.ZERO, value)
	show_status(properties.message)

func manage_facility(action_name: String, value: int) -> void:
	var facility: Dictionary = buildings.selected.get("facility", {})
	if not facility.is_empty():
		action(action_name, facility.assetId, facility.id, value)

func inspect_asset(id: String) -> void:
	property_target = id
	properties.plot_id = id
	properties.queue_redraw()
	var asset: Dictionary = properties.by_asset[id]
	camera.goal = construction.world.project(Vector2(asset.x, asset.y))
	show_business("asset")

func begin_on_plot(kind: String) -> void:
	properties.plot_id = property_target
	show_business("")
	construction.begin(kind)

func refresh_business() -> void:
	if property_panel == null:
		return
	property_panel.visible = not property_view.is_empty()
	if not property_panel.visible:
		return
	var snapshot: Dictionary = properties.state
	var key := property_view + "/" + property_target
	if is_same(snapshot, property_snapshot) and property_message == properties.message and property_key == key and not property_signature.is_empty():
		return
	property_snapshot = snapshot
	property_message = properties.message
	property_key = key
	var signature := JSON.stringify([property_view, property_target, properties.message, snapshot.get("period"),
		snapshot.get("company"), snapshot.get("leases"), snapshot.get("facilities"), snapshot.get("market")])
	if signature == property_signature:
		return
	property_signature = signature
	property_image.hide()
	for child in property_layout.get_children():
		if child != property_text and child != property_image and child != dock_status:
			property_layout.remove_child(child)
			child.queue_free()
	if properties.state.is_empty():
		property_text.text = properties.message
	else:
		match property_view:
			"assets":
				property_text.text = "Tài sản Tràng An · Chọn để xem điều kiện"
				for asset: Dictionary in properties.state.assets:
					add_button(property_layout, asset.name, inspect_asset.bind(asset.id))
			"company":
				var company: Dictionary = properties.state.company
				var amounts: Dictionary = properties.state.amounts if properties.state.amounts != null else {}
				property_text.text = "%s\nVốn %sk · Doanh thu %sk · Chi phí %sk" % [
					company.name, company.balance, amounts.get("revenue", 0), amounts.get("expenses", 0)]
				for contract: Dictionary in properties.state.leases.slice(0, 6):
					var label: String = properties.by_asset[contract.assetId].name
					add_button(property_layout, "%s · %s" % [label, contract.status], inspect_asset.bind(contract.assetId))
			"market":
				var market: Dictionary = properties.state.market
				property_text.text = "Thị trường Tràng An\nNhu cầu kỳ: %d · Doanh nghiệp phục vụ: %d\nDịch vụ NPC đã phục vụ: %d\nChu kỳ thị trường: 15 giây" % [market.demand, market.served, market.npcServed]
				for sector: Dictionary in properties.state.get("sectors", []):
					property_text.text += "\n%s · Công suất %d · Giá TB %sk" % [
						buildings.definitions[sector.kind].name, sector.capacity, sector.averagePrice]
			"asset":
				show_asset()
	add_button(property_layout, "Đóng", show_business.bind(""))

func update_dock_status() -> void:
	if dock_status == null:
		return
	dock_status.visible = property_panel.visible and property_view == "asset" and property_target == "dock"
	if not dock_status.visible:
		return
	var record: Dictionary = properties.by_facility.get("dock", {})
	if record.is_empty():
		return
	var service: Dictionary = simulation.services.instances.get(record.sprite.get_instance_id(), {})
	if service.is_empty():
		return
	var waiting := 0
	for guest in service.queue:
		waiting += int(guest.party)
	var market: Dictionary = simulation.dock_market
	var period := int(market.get("period", -1))
	var seats := mini(simulation.services.capacity(service), int(market.get("dockSeats", 0)))
	var fare := int(market.get("dockFare", service.price))
	var pending := period > simulation.used_dock_period
	var remaining := float(service.remaining)
	var next := "Chờ khách"
	if remaining > 0:
		next = "Thuyền về sau %d giây mô phỏng" % ceili(remaining)
	elif not pending or seats == 0:
		next = "Chờ phân bổ kỳ thị trường tiếp theo"
	dock_status.text = "Giá vé  %dk  ·  Đang chờ  %d khách\nChỗ mở  %d  ·  %s\nDoanh thu bến kỳ server  %.0fk" % [
		fare, waiting, seats if pending and remaining <= 0 else 0, next, market.get("dockGross", 0)]

func show_asset() -> void:
	var asset: Dictionary = properties.by_asset.get(property_target, {})
	if asset.is_empty():
		return
	var contract: Dictionary = properties.lease(asset.id)
	var periods: int = int(properties.state.rentPeriod)
	var term: int = int(properties.state.term)
	property_text.text = "%s\n\n%s · %d × %d ô · Chủ đất: %s" % [asset.name, asset.zone, asset.width, asset.height, asset.owner]
	for record in buildings.placed:
		if record.get("facility", {}).get("assetId", "") != asset.id:
			continue
		property_image.texture = record.sprite.texture
		property_image.show()
		var service: Dictionary = simulation.services.instances.get(record.sprite.get_instance_id(), {})
		if not service.is_empty() and asset.id != "dock":
			property_text.text += "\n\n%s  ·  Giá %dk\n%d nhân viên  ·  %d nhóm đang chờ\nĐang phục vụ %d/%d" % [
				"Mở cửa" if service.staff > 0 else "Tạm đóng", service.price, service.staff, service.queue.size(),
				simulation.services.busy(service), simulation.services.capacity(service)]
	if asset.rent <= 0:
		property_text.text += "\nKhu dịch vụ công cộng hoặc bảo tồn."
		return
	property_text.text += "\nThuê %sk/%d phút · Cọc %sk · Hạn %d phút" % [asset.rent, periods / 4, asset.deposit, term / 4]
	if contract.is_empty():
		if not asset.allowed.is_empty():
			var allowed_names := PackedStringArray()
			for kind: String in asset.allowed.split(","):
				allowed_names.append(buildings.definitions[kind].name)
			property_text.text += "\nĐược xây: %s · Có đường kết nối" % ", ".join(allowed_names)
		add_button(property_layout, "Ký hợp đồng · %sk" % (asset.rent + asset.deposit), action.bind("lease", asset.id))
		return
	var remaining := maxi(0, int(contract.end - properties.state.period) * 15)
	var paid := maxi(0, int(contract.paidThrough - properties.state.period) * 15)
	property_text.text += "\nBên thuê: %s · Còn %ds · Đã trả đến %ds" % [properties.state.company.name, remaining, paid]
	add_button(property_layout, "Trả tiền thuê", action.bind("pay", asset.id))
	add_button(property_layout, "Gia hạn", action.bind("renew", asset.id))
	add_button(property_layout, "Chấm dứt", action.bind("end", asset.id))
	if not asset.allowed.is_empty():
		for kind: String in asset.allowed.split(","):
			add_button(property_layout, "Xây %s · 900k" % buildings.definitions[kind].name, begin_on_plot.bind(kind))
	for facility: Dictionary in properties.state.facilities:
		if facility.assetId != asset.id:
			continue
		property_text.text += "\n%s · Chủ %s · Cấp %d · %sk · %d nhân viên" % [
			buildings.definitions[facility.kind].name, facility.owner, facility.level, facility.price, facility.staff]
		add_button(property_layout, "Tăng giá +10k", action.bind("price", asset.id, facility.id, int(facility.price) + 10))
		add_button(property_layout, "Giảm giá −10k", action.bind("price", asset.id, facility.id, int(facility.price) - 10))
		add_button(property_layout, "Tuyển nhân viên", action.bind("staff", asset.id, facility.id, int(facility.staff) + 1))
		add_button(property_layout, "Giảm nhân viên", action.bind("staff", asset.id, facility.id, int(facility.staff) - 1))
		add_button(property_layout, "Nâng cấp", action.bind("upgrade", asset.id, facility.id))
		add_button(property_layout, "Đóng cửa" if facility.open else "Mở cửa", action.bind("open", asset.id, facility.id, int(not facility.open)))
func menu_icon(title: String) -> Texture2D:
	var shapes := {
		"Xây dựng":"M3 6l4-4 5 5-2 2-2-2-5 5-2-2 5-5z",
		"Công trình":"M2 7l6-5 6 5v7h-4v-4H6v4H2z",
		"Nhân viên":"M8 2a2.4 2.4 0 1 1 0 4.8A2.4 2.4 0 0 1 8 2M3 14v-2a5 5 0 0 1 10 0v2z",
		"Đất & Cơ sở":"M1 8l7-5 7 5-7 5z",
		"Doanh nghiệp":"M1 5h14v9H1zM5 2h6v2H5z",
		"Thị trường":"M2 12l4-5 3 2 5-6v4h-2l-3 4-3-2-3 4z",
		"Báo cáo / Nhật ký":"M2 2h12v12H2zM4 5h8v1H4zM4 8h8v1H4zM4 11h6v1H4z",
		"Đường đi":"M2 1h3l2 5-3 4 2 5H3l-2-5 3-4zm7 0h3l2 5-3 4 2 5h-3l-2-5 3-4z",
		"Bản đồ":"M8 1a5 5 0 0 1 5 5c0 3-5 9-5 9S3 9 3 6a5 5 0 0 1 5-5m0 3a2 2 0 1 0 0 4 2 2 0 0 0 0-4"
	}
	if not shapes.has(title):
		return null
	var image := Image.new()
	image.load_svg_from_string('<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 16 16"><path fill="#f0db9b" fill-rule="evenodd" d="%s"/></svg>' % shapes[title])
	return ImageTexture.create_from_image(image)