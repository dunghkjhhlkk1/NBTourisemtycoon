extends Node2D

var world: WorldManager

func setup(map: WorldManager) -> void:
	world = map
	z_index = -8
	var props := [
		["props/prop_direction_sign", Vector2(12.0,25.8), 72],
		["prototypes/trang_an/shelter-hd", Vector2(30.75,29.7), 260],
		["props/prop_wooden_fence_straight", Vector2(30.2,29.65), 84],
		["props/prop_wooden_fence_straight", Vector2(31.0,30.25), 84],
		["props/prop_direction_sign", Vector2(30.2,28.7), 70],
		["props/prop_wooden_fence_straight", Vector2(30.1,30.55), 91],
		["props/prop_wooden_fence_straight", Vector2(32.8,30.9), 91],
		["props/prop_street_lamp", Vector2(31.8,30.2), 74],
		["props/prop_street_lamp", Vector2(17.5,24.95), 69],
		["props/prop_wooden_bench", Vector2(24.2,25.65), 70],
		["props/prop_wooden_bench", Vector2(28.8,24.95), 70],
		["props/prop_flower_pot", Vector2(24.0,23.0), 45],
		["props/prop_flower_pot", Vector2(26.5,22.9), 45],
		["props/prop_flower_pot", Vector2(29.6,23.05), 39],
		["props/prop_street_lamp", Vector2(32.6,27.45), 68],
		["nature/nature_flowering_tree", Vector2(27.7,21.2), 148],
		["nature/nature_tree_large_02", Vector2(22.0,21.0), 153],
		["nature/nature_tree_large_01", Vector2(19.3,27.2), 174],
		["nature/nature_flowering_tree", Vector2(28.0,27.4), 141],
		["nature/nature_tree_large_02", Vector2(34.4,26.6), 141],
		["terrain/terrain_limestone_cliff_large", Vector2(20.1,16.0), 565],
		["terrain/terrain_limestone_cliff_large", Vector2(25.0,14.6), 640],
		["terrain/terrain_limestone_cliff_medium", Vector2(28.8,16.0), 490],
		["terrain/terrain_limestone_cliff_medium", Vector2(37.7,26.1), 265],
		["terrain/terrain_limestone_cliff_large", Vector2(34.4,14.6), 570],
		["terrain/terrain_limestone_cliff_medium", Vector2(39.2,16.8), 440],
		["nature/nature_tree_large_02", Vector2(36.6,20.2), 225],
		["nature/nature_flowering_tree", Vector2(31.6,18.6), 190],
		["nature/nature_tree_large_01", Vector2(10.0,22.5), 208],
		["nature/nature_flowering_tree", Vector2(12.5,22.9), 172],
		["nature/nature_bamboo_cluster", Vector2(27.0,29.7), 108]
	]
	for item: Array in props:
		world.decorate(item[0], item[1], item[2])
	build_entrance()
	add_sign("KHU CHỜ LÊN THUYỀN", world.project(Vector2(30.75,29.7)) + Vector2(0,-85), Color("#25493f"))
	plantings()
	queue_redraw()

func build_entrance() -> void:
	var cell := Vector2(float(world.ground.gate[0]), float(world.ground.gate[1])) + Vector2(0.5, 0.5)
	world.decorate("prototypes/trang_an/gate-quality2.svg", cell, 300)
	add_sign("KHU DU LỊCH TRÀNG AN", world.project(cell) + Vector2(0,-93), Color("#4b2f1d"))

func add_sign(title: String, point: Vector2, fill: Color) -> void:
	var plate := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = Color("#f0c476")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	plate.add_theme_stylebox_override("panel", style)
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color("#fff1cc"))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_child(label)
	plate.z_index = 2
	add_child(plate)
	plate.z_as_relative = false
	plate.position = point - Vector2(plate.get_combined_minimum_size().x / 2.0, 0)

func plantings() -> void:
	var random := RandomNumberGenerator.new()
	random.seed = 319
	var trees := ["nature/nature_tree_large_01", "nature/nature_tree_large_02", "nature/nature_flowering_tree", "nature/nature_bamboo_cluster"]
	for index in range(42):
		var cell := Vector2(random.randf_range(9.0,37.5), random.randf_range(13.0,19.1))
		world.decorate(trees[index % trees.size()], cell, random.randf_range(95.0,200.0), index % 2 == 0)
	for x in range(12, 42):
		for y in range(27, 36):
			var cell := Vector2i(x, y)
			if not world.water_cells.has(cell) or world.water_cells.has(cell + Vector2i.UP):
				continue
			var bank := cell + Vector2i.UP
			if Rect2i(29, 27, 6, 7).has_point(bank) or world.road_cells.has(bank):
				continue
			var plant := "nature/nature_bush_green" if x % 3 == 0 else "nature/nature_bush_flower_yellow"
			world.decorate(plant, Vector2(bank) + Vector2(0.55, 0.75), random.randf_range(46, 85))
	var beds := [Vector2(12.75,25.05), Vector2(14.0,26.75), Vector2(16.2,27.55),
		Vector2(21.2,27.5), Vector2(22.4,27.7), Vector2(24.2,27.8),
		Vector2(26.5,28.7), Vector2(28.3,28.7), Vector2(33.9,29.7),Vector2(18.9,23.0), Vector2(22.7,23.1), Vector2(24.8,25.5),
		Vector2(27.4,23.1), Vector2(29.1,25.45), Vector2(30.1,27.9),
		Vector2(32.8,29.55), Vector2(34.9,27.3), Vector2(18.0,25.35)]
	for center: Vector2 in beds:
		for index in range(5):
			var cell := center + Vector2(random.randf_range(-0.43,0.43),random.randf_range(-0.35,0.35))
			if not world.road_cells.has(Vector2i(cell.floor())):
				var flower := "nature/nature_bush_flower_pink" if index % 2 == 0 else "nature/nature_bush_flower_yellow"
				world.decorate(flower, cell, random.randf_range(48.0,91.0), index >= 2)
	for x in range(18,40):
		for y in range(27,35):
			var cell := Vector2i(x,y)
			if not world.water_cells.has(cell):
				continue
			if not world.water_cells.has(cell + Vector2i.UP) and not Rect2i(30,31,4,3).has_point(cell):
				world.decorate("nature/nature_rock_medium", Vector2(cell) + Vector2(0.40,0.1), random.randf_range(46,89), x % 2 == 0)
			elif y >= 33 and random.randf() < 0.18:
				world.decorate("nature/nature_lily_pad_cluster", Vector2(cell) + Vector2(0.18,0.4), random.randf_range(29,57), true)

func quad(cell: Vector2, size: Vector2, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		world.project(cell), world.project(cell + Vector2(size.x,0)), world.project(cell + size),
		world.project(cell + Vector2(0,size.y))]), color)

func _draw() -> void:
	if world == null:
		return
	var random := RandomNumberGenerator.new()
	random.seed = 8706
	for cell: Vector2i in world.road_cells:
		var center := Vector2(cell) + Vector2(0.5, 0.5)
		var width := 0.95 if cell.y == 24 else 0.83
		draw_circle(world.project(center), 13.0, Color("#8c7959"))
		for step: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN]:
			if world.road_cells.has(cell + step):
				walkway(center, center + Vector2(step), width, random)

	# The paved courtyards join the promenade at their entrances.
	for area: Array in [
		[Vector2(10.15, 24.55), Vector2(13.45, 24.55), 2.1],
		[Vector2(16.0, 23.15), Vector2(18.8, 23.85), 1.65],
		[Vector2(20.8, 22.1), Vector2(21.55, 24.45), 1.22],
		[Vector2(23.0, 23.0), Vector2(26.7, 23.6), 1.76],
		[Vector2(30.8, 22.9), Vector2(30.5, 24.5), 1.28],
		[Vector2(30.3, 28.35), Vector2(31.5, 30.9), 2.7]
	]:
		walkway(area[0], area[1], area[2], random)

	quad(Vector2(10.45,24.8), Vector2(1.7,0.6), Color(0.14,0.12,0.10,0.19))
	quad(Vector2(30.0,30.6), Vector2(4.1,2.5), Color("#6b4629"))
	quad(Vector2(31.35,32.8), Vector2(1.05,1.1), Color("#8e603d"))
	var quay_edge := world.project(Vector2(30.0, 33.1))
	var quay_end := world.project(Vector2(34.1, 33.1))
	draw_line(quay_edge + Vector2(0, 7), quay_end + Vector2(0, 7), Color("#503827"), 14)
	for index in range(9):
		var post := quay_edge.lerp(quay_end, index / 8.0)
		draw_line(post - Vector2(0, 9), post + Vector2(0, 30), Color("#694327"), 11)
		draw_line(post - Vector2(2, 9), post + Vector2(-2, 23), Color("#d4a46b"), 3)
	for plank in range(8):
		quad(Vector2(31.40,32.82 + plank * 0.128), Vector2(0.96,0.108), Color("#c18d59"))
	for row in range(19):
		quad(Vector2(30.08,30.64 + float(row) * 0.126), Vector2(3.98,0.113),
			Color("#deb17a").lerp(Color("#ad7448"),random.randf()))

func walkway(start: Vector2, finish: Vector2, width: float, random: RandomNumberGenerator) -> void:
	var direction := (finish - start).normalized()
	var edge := direction.orthogonal() * width / 2.0
	var rows := ceili(start.distance_to(finish) * 5.0)
	var columns := ceili(width * 4.0)
	for row in range(rows):
		var near := start.lerp(finish, float(row) / rows)
		var far := start.lerp(finish, float(row + 1) / rows)
		var inset := 0.12 * absf(float(row) / maxf(1, rows - 1) * 2.0 - 1.0)
		stone(near - edge * (1.0 - inset), near + edge * (1.0 - inset),
			far + edge * (1.0 - inset), far - edge * (1.0 - inset), Color("#827359"))
		var left := inset / 2.0
		for column in range(columns):
			var right := 1.0 - inset / 2.0 if column == columns - 1 else (float(column + 1) + random.randf_range(-0.22, 0.22)) / columns
			var tint := Color("#e3cba2").lerp(Color("#a89474"), random.randf_range(0.02, 0.83))
			stone(near.lerp(far, 0.035) + edge * (2.0 * left - 0.98),
				near.lerp(far, 0.035) + edge * (2.0 * right - 1.02),
				far.lerp(near, 0.045) + edge * (2.0 * right - 1.02),
				far.lerp(near, 0.045) + edge * (2.0 * left - 0.98), tint)
			left = right

func stone(a: Vector2, b: Vector2, c: Vector2, d: Vector2, tint: Color) -> void:
	draw_colored_polygon(PackedVector2Array([world.project(a), world.project(b),
		world.project(c), world.project(d)]), tint)
