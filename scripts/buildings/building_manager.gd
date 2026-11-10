class_name BuildingManager
extends Node

signal changed
signal selection_changed(record: Dictionary)

var world: WorldManager
var presentation_scale := 1.0
var definitions := {}
var occupied := {}
var placed: Array[Dictionary] = []
var selected: Dictionary = {}
var sprite_masks := {}
var visitor_cells := {}
var may_remove: Callable

func setup(map: WorldManager) -> void:
	world = map
	var data: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/buildings.json"))
	for def: Dictionary in data:
		definitions[def.id] = def
		place(def.id, Vector2i(int(def.start[0]), int(def.start[1])))

func dimensions(def: Dictionary) -> Vector2i:
	return Vector2i(int(def.size[0]), int(def.size[1]))

func cells(def: Dictionary, origin: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var size := dimensions(def)
	for y in range(size.y):
		for x in range(size.x):
			result.append(origin + Vector2i(x,y))
	return result

func allowed(def: Dictionary, origin: Vector2i, persistent := false) -> bool:
	var wet := 0
	var footprint := cells(def, origin)
	for cell in footprint:
		if not world.inside(cell) or occupied.has(cell) or (not persistent and visitor_cells.has(cell)):
			return false
		if world.water_cells.has(cell):
			wet += 1
	if def.shore:
		return wet > 0 and wet < footprint.size()
	return wet == 0

func anchor(def: Dictionary, origin: Vector2i) -> Vector2:
	var size := Vector2(dimensions(def))
	return world.project(Vector2(origin) + size / 2) + Vector2(0, size.y * 13)

func make_sprite(def: Dictionary) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = load("res://assets/" + def.sprite)
	sprite.scale = Vector2.ONE * float(def.width) * presentation_scale / sprite.texture.get_width()
	var bounds: Rect2i
	if not sprite_masks.has(def.id):
		var pixels := sprite.texture.get_image()
		sprite_masks[def.id] = [pixels, pixels.get_used_rect()]
	bounds = sprite_masks[def.id][1]
	sprite.offset.y = sprite.texture.get_height() / 2.0 - bounds.end.y
	return sprite

func place(id: String, origin: Vector2i, persistent := false) -> Dictionary:
	var def: Dictionary = definitions[id]
	if not allowed(def, origin, persistent):
		return {}
	var sprite := make_sprite(def)
	sprite.position = anchor(def, origin)
	world.objects.add_child(sprite)
	var record := {"def": def, "cell": origin, "sprite": sprite}
	placed.append(record)
	for cell in cells(def, origin):
		occupied[cell] = record
	changed.emit()
	return record

func select(record: Dictionary) -> void:
	if not selected.is_empty():
		selected.sprite.modulate = Color.WHITE
	selected = record
	if not selected.is_empty():
		selected.sprite.modulate = Color(1.12, 1.23, 0.84)
	selection_changed.emit(selected)

func select_at(point: Vector2) -> void:
	var best: Dictionary = {}
	var depth := -INF
	for record in placed:
		var sprite: Sprite2D = record.sprite
		var rect := sprite.get_rect()
		var local := sprite.to_local(point)
		if not rect.has_point(local) or sprite.position.y < depth:
			continue
		var pixels: Image = sprite_masks[record.def.id][0]
		if pixels.get_pixelv(Vector2i(local - rect.position)).a > 0.25:
			best = record
			depth = sprite.position.y
	select(best)

func remove_selected() -> void:
	if selected.is_empty():
		return
	var record := selected
	if may_remove.is_valid() and not may_remove.call(record):
		return
	select({})
	for cell in cells(record.def, record.cell):
		occupied.erase(cell)
	placed.erase(record)
	record.sprite.queue_free()
	changed.emit()
