class_name WorldManager
extends Node2D

const SIDE := 48
const U := Vector2(72, -24)
const V := Vector2(56, 40)
const GROUND_Y_SCALE := 0.76
const FOCUS := Vector2(3225, 425 * GROUND_Y_SCALE)
const BOUNDS := Rect2(0, -1152 * GROUND_Y_SCALE, 6144, 3072 * GROUND_Y_SCALE)
const STEPS := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

var objects: Node2D
var road_cells := {}
var water_cells := {}
var ground: Dictionary

func _ready() -> void:
	ground = JSON.parse_string(FileAccess.get_file_as_string("res://data/world.json"))
	var offline := "--offline-v02" in OS.get_cmdline_user_args()
	for cell: Array in (ground.legacy_roads if offline else ground.roads):
		road_cells[Vector2i(int(cell[0]), int(cell[1]))] = true
	for cell: Array in ground.water:
		water_cells[Vector2i(int(cell[0]), int(cell[1]))] = true
	if offline:
		for chunk: Array in ground.chunks:
			var sprite := Sprite2D.new()
			sprite.texture = load("res://assets/terrain/chunk_%s.png" % chunk[0])
			sprite.centered = false
			sprite.position = Vector2(float(chunk[1]), float(chunk[2]) * GROUND_Y_SCALE)
			sprite.scale.y = GROUND_Y_SCALE
			sprite.z_index = -10
			add_child(sprite)
	else:
		build_landscape()
	objects = Node2D.new()
	objects.name = "DepthSortedObjects"
	objects.y_sort_enabled = true
	add_child(objects)

func project(cell: Vector2) -> Vector2:
	var point := U * cell.x + V * cell.y
	return Vector2(point.x, point.y * GROUND_Y_SCALE)

func unproject(point: Vector2) -> Vector2:
	var y := point.y / GROUND_Y_SCALE
	return Vector2(40 * point.x - 56 * y, 24 * point.x + 72 * y) / 4224.0

func cell_at(point: Vector2) -> Vector2i:
	return Vector2i(unproject(point).floor())

func inside(cell: Vector2i) -> bool:
	return Rect2i(0, 0, SIDE, SIDE).has_point(cell)

func cell_center(cell: Vector2i) -> Vector2:
	return project(Vector2(cell) + Vector2(0.5, 0.5))

func decorate(file: String, cell: Vector2, width: float, extra_detail := false) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = load("res://assets/" + (file if file.ends_with(".svg") else file + ".png"))
	var factor := width / sprite.texture.get_width()
	sprite.scale = Vector2.ONE * factor
	sprite.offset.y = -sprite.texture.get_height() / 2.0 + sprite.texture.get_height() * 0.06
	sprite.position = project(cell)
	objects.add_child(sprite)
	if extra_detail:
		sprite.add_to_group("scenery_detail")


func build_landscape() -> void:
	var bank_map := Image.create_empty(SIDE, 1, false, Image.FORMAT_RGB8)
	for x in range(SIDE):
		var first := SIDE
		var last := 0
		for y in range(SIDE):
			if water_cells.has(Vector2i(x, y)):
				first = mini(first, y)
				last = y + 1
		# The quay spans a break in the navigable water cells.
		if x == 31 or x == 32:
			first = 31
		bank_map.set_pixel(x, 0, Color(float(first) / SIDE, float(last) / SIDE, 0))
	var surface := Polygon2D.new()
	surface.polygon = PackedVector2Array([project(Vector2(-8, -8)), project(Vector2(SIDE + 8, -8)),
		project(Vector2(SIDE + 8, SIDE + 8)), project(Vector2(-8, SIDE + 8))])
	var material := ShaderMaterial.new()
	material.shader = preload("res://assets/terrain/trang_an_landscape.gdshader")
	material.set_shader_parameter("ground_y_scale", GROUND_Y_SCALE)
	material.set_shader_parameter("banks", ImageTexture.create_from_image(bank_map))
	surface.material = material
	surface.z_index = -10
	add_child(surface)