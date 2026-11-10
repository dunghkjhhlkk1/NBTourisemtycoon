class_name ConstructionController
extends Node2D

signal status_changed(message: String)
var manager: BuildingManager
var simulation: VisitorController
var properties
var sending := false
const BUILD_COST := 350
var world: WorldManager
var preview: Sprite2D
var active := ""
var hovered := Vector2i(-1,-1)
var can_place := false
var pointer := Vector2.ZERO

func begin(id: String) -> void:
	cancel()
	active = id
	preview = manager.make_sprite(manager.definitions[id])
	add_child(preview)
	status_changed.emit("Xây 900k · Nhấp trong lô đã thuê" if properties != null else "Xây 350k · Esc hoặc chuột phải để hủy")
	update_preview()

func cancel() -> void:
	if preview != null:
		preview.queue_free()
		preview = null
	active = ""
	queue_redraw()
	status_changed.emit("")

func _process(_delta: float) -> void:
	if not active.is_empty():
		update_preview()

func update_preview() -> void:
	var def: Dictionary = manager.definitions[active]
	hovered = world.cell_at(get_canvas_transform().affine_inverse() * pointer)
	can_place = manager.allowed(def, hovered)
	if properties != null:
		can_place = can_place and properties.permits(active, hovered)
	preview.visible = world.inside(hovered)
	preview.position = manager.anchor(def, hovered)
	preview.modulate = Color(0.55, 1, 0.62, 0.65) if can_place else Color(1, 0.38, 0.38, 0.65)
	queue_redraw()

func _draw() -> void:
	if active.is_empty() or not world.inside(hovered):
		return
	var origin := Vector2(hovered)
	var size := Vector2(manager.dimensions(manager.definitions[active]))
	var outline := PackedVector2Array([world.project(origin), world.project(origin + Vector2(size.x,0)), world.project(origin + size), world.project(origin + Vector2(0,size.y))])
	draw_colored_polygon(outline, Color(0.25, 1, 0.45, 0.32) if can_place else Color(1, 0.16, 0.16, 0.34))
	outline.append(outline[0])
	draw_polyline(outline, Color.PALE_GREEN if can_place else Color.SALMON, 3, true)

func _input(event: InputEvent) -> void:
	if event is InputEventMouse:
		pointer = event.position

func _unhandled_input(event: InputEvent) -> void:
	if sending:
		return
	if event.is_action_pressed("ui_cancel"):
		cancel()
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_DELETE:
		manager.remove_selected()
	if not (event is InputEventMouseButton and event.pressed):
		return
	if event.button_index == MOUSE_BUTTON_RIGHT:
		cancel()
	elif event.button_index == MOUSE_BUTTON_LEFT:
		pointer = event.position
		if active.is_empty():
			manager.select_at(get_canvas_transform().affine_inverse() * event.position)
		else:
			update_preview()
			if can_place:
				if properties != null:
					sending = true
					var built: bool = await properties.command("build", properties.plot_id, active, hovered)
					sending = false
					if built:
						cancel()
					status_changed.emit(properties.message)
					return
				if simulation != null and simulation.economy.cash < BUILD_COST:
					status_changed.emit("Cần 350k để xây công trình.")
					return
				var record := manager.place(active, hovered)
				if simulation != null and not record.is_empty():
					simulation.economy.record("Xây dựng", -BUILD_COST, record.sprite.get_instance_id(), 0, simulation.elapsed)
				cancel()
				manager.select(record)
			else:
				status_changed.emit("Ô đang bị chiếm, sai địa hình hoặc ngoài bản đồ.")
