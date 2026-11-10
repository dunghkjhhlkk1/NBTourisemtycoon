extends Node2D

const ART := "res://assets/prototypes/trang_an/"
const MAP_SIZE := Vector2(1672, 941)
const MOORING := Vector2(1146, 596)
const QUEUE := [Vector2(662, 545), Vector2(684, 541), Vector2(706, 536), Vector2(728, 532),
	Vector2(750, 528), Vector2(772, 524), Vector2(791, 517), Vector2(813, 511),
	Vector2(833, 506), Vector2(855, 501), Vector2(875, 496), Vector2(897, 492)]
const WALK := [Vector2(58, 643), Vector2(180, 584), Vector2(308, 557),
	Vector2(375, 519), Vector2(478, 556), Vector2(565, 556), Vector2(661, 541),
	Vector2(769, 513), Vector2(891, 487), Vector2(978, 505), Vector2(1087, 534), MOORING]
const CRUISE := [MOORING, Vector2(1216, 637), Vector2(1358, 592), Vector2(1491, 468),
	Vector2(1416, 350), Vector2(1325, 263), Vector2(1318, 212)]
var camera := Camera2D.new()
var actors := Node2D.new()
var passengers: Array[Sprite2D] = []
var boats: Array[Sprite2D] = []
var wakes: Array[Line2D] = []
var walk := Curve2D.new()
var cruise := Curve2D.new()
var clock := 0.0
var fit := 1.0
var target := Vector2(836, 470.5)
var zoom_factor := 1.0
var dragging := false
var speed := 1.0
var stats := Label.new()
var log := Label.new()
var details := Label.new()
var tick := 0.0
var sites: Array[Area2D] = []
var selected: Area2D
var view_name := "Toàn cảnh"
var toolbar_message := ""

func _ready() -> void:
	var landscape := Node2D.new()
	landscape.name = "ObjectLandscape"
	landscape.set_script(preload("res://scripts/prototypes/trang_an_object_landscape.gd"))
	landscape.z_index = -3
	add_child(landscape)
	load_sites()
	make_waiting_area()
	add_child(actors)
	actors.y_sort_enabled = true
	make_curve(walk, WALK)
	make_curve(cruise, CRUISE)
	var people := [
		preload("res://assets/characters/character_tourist_male_idle.png"),
		preload("res://assets/characters/character_tourist_female_idle.png"),
		preload("res://assets/characters/character_tourist_backpacker_idle.png"),
		preload("res://assets/characters/character_tourist_elderly_female_idle.png")
	]
	for i in range(28):
		var guest := sprite(people[i % people.size()], 43.0 + float(i % 3) * 3.0)
		var material := ShaderMaterial.new()
		material.shader = preload("res://assets/prototypes/trang_an/walk.gdshader")
		guest.material = material
		passengers.append(guest)
	var craft := preload("res://assets/prototypes/trang_an/occupied-sampan.png")
	for i in range(3):
		var wake := Line2D.new()
		wake.width = 2.0
		wake.antialiased = true
		wake.default_color = Color(0.79, 0.98, 0.91, 0.58)
		actors.add_child(wake)
		wake.z_index = -1
		wakes.append(wake)
		boats.append(sprite(craft, 150.0 if i < 2 else 128.0))
	add_child(camera)
	camera.make_current()
	make_hud()
	get_viewport().size_changed.connect(apply_camera)
	apply_camera()

func sprite(texture: Texture2D, width: float) -> Sprite2D:
	var item := Sprite2D.new()
	item.texture = texture
	item.scale = Vector2.ONE * width / texture.get_width()
	item.offset.y = -texture.get_height() * 0.38
	actors.add_child(item)
	return item

func make_curve(curve: Curve2D, points: Array) -> void:
	for i in range(points.size()):
		var tangent: Vector2 = (points[mini(i + 1, points.size() - 1)] - points[maxi(i - 1, 0)]) * 0.13
		curve.add_point(points[i], -tangent, tangent)

func _process(delta: float) -> void:
	clock += delta * speed
	var waiting := 0
	var aboard := 0
	var walk_length := walk.get_baked_length()
	var queue_end := walk.get_closest_offset(QUEUE[0])
	var boarding_start := walk.get_closest_offset(QUEUE[QUEUE.size() - 1])
	for i in range(passengers.size()):
		var previous := passengers[i].position
		var phase := fposmod(clock + i * 2.38 + 8.0, 66.6)
		var guest := passengers[i]
		guest.visible = phase < 55.0
		if phase < 29.0:
			var distance := queue_end * phase / 29.0
			guest.position = walk.sample_baked(distance) + Vector2(0, (i % 3 - 1) * 7)
		elif phase < 45.0:
			var slot := clampi(floori((45.0 - phase) / 2.38), 0, QUEUE.size() - 1)
			guest.position = QUEUE[QUEUE.size() - 1 - slot]
			waiting += 1
		elif phase < 55.0:
			guest.position = walk.sample_baked(lerpf(boarding_start, walk_length, (phase - 45.0) / 10.0))
		else:
			aboard += 1
		var displacement: Vector2 = guest.position - previous
		var walking := guest.visible and speed > 0.0 and displacement.length_squared() > 0.001 and displacement.length_squared() < 900.0
		var animation: ShaderMaterial = guest.material
		animation.set_shader_parameter("moving", 1.0 if walking else 0.0)
		animation.set_shader_parameter("stride", clock * 10.0 + i * 0.8)
		guest.rotation = sin(clock * 10.0 + i * 0.8) * 0.045 if walking else 0.0
		guest.offset.y = -guest.texture.get_height() * 0.38 - (absf(sin(clock * 10.0 + i * 0.8)) * 6.0 if walking else 0.0)
		if walking and absf(displacement.x) > 0.01:
			guest.flip_h = displacement.x < 0.0
	for i in range(boats.size()):
		var phase := fposmod(clock / 35.0 + i * 0.66, 2.0)
		var going := phase < 1.0
		var progress := phase if going else 2.0 - phase
		var distance := progress * cruise.get_baked_length()
		var point := cruise.sample_baked(distance)
		point += Vector2(-38.0 * i * sin(progress * PI), 48.0 * i * sin(progress * PI))
		var tangent := cruise.sample_baked(minf(cruise.get_baked_length(), distance + 8.0)) - cruise.sample_baked(maxf(0, distance - 8.0))
		var direction := tangent.normalized() * (1.0 if going else -1.0)
		var boat := boats[i]
		boat.position = point
		boat.flip_h = direction.x < 0.0
		boat.rotation = sin(clock * 2.0 + i) * 0.025
		var wake := wakes[i]
		wake.position = point + Vector2(0, 10)
		wake.visible = progress > 0.025 and progress < 0.98
		wake.points = PackedVector2Array([-direction * 38.0, -direction * 64.0 + Vector2(0, 4),
			-direction * 96.0 + Vector2(0, 1)])
	tick += delta
	if tick >= 0.35:
		tick = 0.0
		stats.text = " TRÀNG AN V0.4  │  💰 1.568k  │  👥 %d khách  │  Ngày 2 · 10:24  │  ☺ Hài lòng: 86%%  │  Doanh thu: 415k (Lãi: 305k)" % passengers.size()
		if is_instance_valid(selected):
			details.text = "%s\n────────────────────\n%s\n\n● Đang hoạt động\nKhách tham quan: %d\nThuyền trên tuyến: %d" % [selected.get_meta("title"), selected.get_meta("description"), passengers.size(), boats.size()]
		else:
			details.text = "Bến thuyền Tràng An\n────────────────────\n⚓ Cấp 1\n♧ Sức chứa: 3 thuyền\n⚑ Đang chờ: %d khách\n♧ Đang phục vụ: %d khách\n⌛ Chuyến tiếp: 2 phút" % [waiting, aboard]
		log.text = "🔔  Bến thuyền: Thuyền 2 sắp khởi hành (2 phút)\n✔  %d khách chờ lên thuyền   ·   %d thuyền hoạt động" % [waiting, boats.size()]

func make_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	layer.add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var theme := Theme.new()
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("#092c28f2")
	panel.border_color = Color("#a1ad60")
	panel.set_border_width_all(1)
	panel.set_corner_radius_all(11)
	panel.content_margin_left = 10
	panel.content_margin_right = 10
	panel.content_margin_top = 7
	panel.content_margin_bottom = 7
	theme.set_stylebox("panel", "PanelContainer", panel)
	theme.set_stylebox("normal", "Button", panel)
	var hover := panel.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#477044")
	theme.set_stylebox("hover", "Button", hover)
	theme.set_stylebox("pressed", "Button", hover)
	theme.set_color("font_color", "Button", Color("#ffefc7"))
	theme.set_color("font_color", "Label", Color("#fff0c9"))
	theme.set_font_size("font_size", "Button", 15)
	theme.set_font_size("font_size", "Label", 16)
	root.theme = theme
	var header := PanelContainer.new()
	root.add_child(header)
	header.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	header.offset_left = 5
	header.offset_right = -5
	header.offset_top = 3
	header.offset_bottom = 39
	header.add_child(stats)
	stats.add_theme_color_override("font_color", Color("#f3df9e"))
	stats.add_theme_font_size_override("font_size", 16)
	var speed_box := HBoxContainer.new()
	root.add_child(speed_box)
	speed_box.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	speed_box.offset_left = -151
	speed_box.offset_right = -5
	speed_box.offset_top = 4
	speed_box.offset_bottom = 35
	add_button(speed_box, "▶", func(): speed = 0.0 if speed > 0.0 else 1.0, Vector2(32, 30))
	add_button(speed_box, "x1", func(): speed = 1.0, Vector2(33, 30))
	add_button(speed_box, "x2", func(): speed = 2.0, Vector2(33, 30))
	add_button(speed_box, "x4", func(): speed = 4.0, Vector2(33, 30))
	var side := VBoxContainer.new()
	side.position = Vector2(9, 51)
	root.add_child(side)
	add_button(side, "Toàn cảnh", focus.bind(Vector2(836, 470), 1.0), Vector2(132, 32))
	add_button(side, "Xây dựng", show_feature.bind("Xây dựng"), Vector2(132, 32))
	add_button(side, "Thuê / Hợp đồng", show_feature.bind("Thuê / Hợp đồng"), Vector2(132, 32))
	add_button(side, "Quản lý doanh nghiệp", show_feature.bind("Quản lý doanh nghiệp"), Vector2(132, 32))
	add_button(side, "Báo cáo", show_feature.bind("Báo cáo"), Vector2(132, 32))
	add_button(side, "Bản đồ", focus.bind(Vector2(836, 470), 1.0), Vector2(132, 32))
	var right := PanelContainer.new()
	root.add_child(right)
	right.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	right.offset_left = -212
	right.offset_right = -10
	right.offset_top = 50
	right.offset_bottom = 204
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.custom_minimum_size = Vector2(180, 138)
	details.add_theme_font_size_override("font_size", 14)
	right.add_child(details)
	var journal := PanelContainer.new()
	root.add_child(journal)
	journal.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	journal.offset_left = 9
	journal.offset_top = -65
	journal.offset_bottom = -8
	log.add_theme_font_size_override("font_size", 14)
	journal.add_child(log)
	var dock := HBoxContainer.new()
	root.add_child(dock)
	dock.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	dock.offset_left = -345
	dock.offset_right = -10
	dock.offset_top = -66
	dock.offset_bottom = -8
	for title in ["Lô đất", "Công trình", "Hợp đồng", "Doanh nghiệp"]:
		add_button(dock, title, show_feature.bind(title), Vector2(78, 56))
	var quick := HBoxContainer.new()
	root.add_child(quick)
	quick.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	quick.offset_left = -286
	quick.offset_right = -10
	quick.offset_top = -100
	quick.offset_bottom = -68
	add_button(quick, "Quầy vé", focus.bind(Vector2(375, 373), 1.6), Vector2(78, 29))
	add_button(quick, "Đường dạo", focus.bind(Vector2(560, 424), 1.55), Vector2(85, 29))
	add_button(quick, "Bến thuyền", focus.bind(Vector2(1010, 480), 1.55), Vector2(88, 29))

func add_button(box: BoxContainer, title: String, action: Callable, size: Vector2) -> void:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size = size
	button.pressed.connect(action)
	box.add_child(button)

func show_feature(title: String) -> void:
	toolbar_message = title
	if title == "Công trình":
		focus(Vector2(836, 470), 1.0)
	elif title == "Bản đồ":
		focus(Vector2(836, 470), 1.0)
	else:
		details.text = "%s\n────────────────────\nBản thử hình ảnh: chọn trực tiếp công trình trên bản đồ để xem thông tin." % title

func focus(point: Vector2, magnification: float) -> void:
	target = point
	zoom_factor = magnification
	apply_camera()

func apply_camera() -> void:
	var viewport := get_viewport_rect().size
	fit = maxf(viewport.x / MAP_SIZE.x, viewport.y / MAP_SIZE.y)
	camera.zoom = Vector2.ONE * fit * zoom_factor
	var half := viewport / camera.zoom / 2.0
	target = target.clamp(half, MAP_SIZE - half)
	camera.position = target

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_HOME:
		focus(MAP_SIZE / 2.0, 1.0)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			select_at(get_global_mouse_position())
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			dragging = event.pressed
		elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			zoom_factor = clampf(zoom_factor * (1.12 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.12), 1.0, 2.8)
			apply_camera()
	if event is InputEventMouseMotion and dragging:
		target -= event.relative / camera.zoom
		apply_camera()


func load_sites() -> void:
	var records: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/trang_an_visual_objects.json"))
	for record: Dictionary in records:
		var site := Area2D.new()
		site.name = record.id
		site.position = Vector2(record.origin[0], record.origin[1])
		site.set_meta("title", record.name)
		site.set_meta("description", record.description)
		site.z_index = -2
		var art := Sprite2D.new()
		art.name = "Artwork"
		art.texture = load("res://assets/buildings/building_ticket_booth_lv1.png") if record.id == "ticket" else load(ART + str(record.id) + "-object.png")
		art.centered = false
		art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		if record.id == "ticket":
			art.scale = Vector2.ONE * 0.38
		if record.id in ["shelter", "pier"]:
			art.texture = load(ART + str(record.id) + "-hd.png")
			var pixels := art.texture.get_image()
			var content := pixels.get_used_rect()
			art.region_enabled = true
			art.region_rect = Rect2(content)
			var size := Vector2(312,177) if record.id == "shelter" else Vector2(358,225)
			art.scale = size / Vector2(content.size)
		site.add_child(art)
		var hit := CollisionPolygon2D.new()
		hit.name = "Outline"
		var polygon := PackedVector2Array()
		for pair: Array in record.outline:
			polygon.append(Vector2(pair[0], pair[1]) - site.position)
		hit.polygon = polygon
		site.add_child(hit)
		add_child(site)
		sites.append(site)

func select_at(point: Vector2) -> void:
	if is_instance_valid(selected):
		selected.get_node("Artwork").modulate = Color.WHITE
	selected = null
	for index in range(sites.size() - 1, -1, -1):
		var site := sites[index]
		var hit: CollisionPolygon2D = site.get_node("Outline")
		if Geometry2D.is_point_in_polygon(site.to_local(point), hit.polygon):
			selected = site
			site.get_node("Artwork").modulate = Color(1.09, 1.06, 0.87)
			break
	tick = 1.0

func make_waiting_area() -> void:
	make_board("KHU CHỜ LÊN THUYỀN", Vector2(731, 429), Color("#6e3b20"), Color("#fff0be"))
	make_board("ĐÃ MUA VÉ\n1. Khu chờ\n2. Lên thuyền", Vector2(571, 502), Color("#f4dba0"), Color("#4a381c"))
	make_board("BẾN THUYỀN TRÀNG AN", Vector2(961, 335), Color("#6e3b20"), Color("#fff0be"))
	for lane in [
		[Vector2(648, 554), Vector2(695, 548), Vector2(742, 541), Vector2(788, 533), Vector2(834, 525), Vector2(881, 516), Vector2(922, 510)],
		[Vector2(649, 554), Vector2(657, 536), Vector2(680, 530)]
	]:
		var previous := Vector2.ZERO
		for point: Vector2 in lane:
			var top := point - Vector2(0, 22)
			if previous != Vector2.ZERO:
				var rope := Line2D.new()
				rope.width = 2.7
				rope.default_color = Color("#ab3525")
				rope.antialiased = true
				rope.points = PackedVector2Array([previous, previous.lerp(top, 0.5) + Vector2(0, 5), top])
				rope.z_index = 1
				add_child(rope)
			var post := Line2D.new()
			post.width = 3.5
			post.default_color = Color("#a78457")
			post.antialiased = true
			post.points = PackedVector2Array([point, top])
			post.z_index = 1
			add_child(post)
			previous = top

func make_board(title: String, point: Vector2, fill: Color, ink: Color) -> void:
	var board := Label.new()
	board.text = title
	board.position = point
	board.rotation = -0.16
	board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.z_index = 2
	board.add_theme_color_override("font_color", ink)
	board.add_theme_font_size_override("font_size", 15)
	var frame := StyleBoxFlat.new()
	frame.bg_color = fill
	frame.border_color = Color("#d8ab6a")
	frame.set_border_width_all(2)
	frame.set_corner_radius_all(4)
	frame.content_margin_left = 7
	frame.content_margin_right = 7
	frame.content_margin_top = 4
	frame.content_margin_bottom = 4
	board.add_theme_stylebox_override("normal", frame)
	add_child(board)
