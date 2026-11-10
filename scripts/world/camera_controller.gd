class_name CameraController
extends Camera2D

signal mode_changed(title: String)
var goal := WorldManager.FOCUS
var zoom_goal := 0.60
var dragging := false
var business_view := false
const DISTRICT_FOCUS := Vector2(3010, 230)
const DISTRICT_ZOOM := 0.47
const DOCK_FOCUS := Vector2(3940, 425)
var fingers := {}
var touch_dragged := false
var touch_target: Callable
var touch_controls := {}

func _ready() -> void:
	if business_view:
		goal = DISTRICT_FOCUS
		zoom_goal = DISTRICT_ZOOM
	position = goal
	zoom = Vector2.ONE * zoom_goal
	make_current()

func set_mode(mode: int) -> void:
	var fit := minf(get_viewport_rect().size.x / (WorldManager.BOUNDS.size.x + 106.0), get_viewport_rect().size.y / (WorldManager.BOUNDS.size.y + 178.0))
	zoom_goal = [fit, DISTRICT_ZOOM if business_view else 0.60, 1.08][mode]
	goal = [WorldManager.BOUNDS.get_center(), DISTRICT_FOCUS if business_view else WorldManager.FOCUS, DOCK_FOCUS][mode]
	mode_changed.emit(["Toàn cảnh", "Quản lý", "Chi tiết"][mode])

func shift_zoom(step: float) -> void:
	zoom_goal = clampf(zoom_goal * step, 0.12, 1.8)
	mode_changed.emit("Thu phóng")

func _process(delta: float) -> void:
	var keys := Vector2(
		float(Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)),
		float(Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)))
	goal += keys.normalized() * 650.0 * delta / zoom_goal
	var half := get_viewport_rect().size / (2.0 * zoom_goal)
	var bounds := WorldManager.BOUNDS
	var margin := Vector2(minf(half.x, bounds.size.x / 2), minf(half.y, bounds.size.y / 2))
	goal = goal.clamp(bounds.position + margin, bounds.end - margin)
	var weight := 1.0 - exp(-delta * 14.0)
	position = position.lerp(goal, weight)
	zoom = zoom.lerp(Vector2.ONE * zoom_goal, weight)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		handle_touch(event)
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE:
		dragging = event.pressed
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and dragging:
		goal -= event.relative / zoom
		get_viewport().set_input_as_handled()

func handle_touch(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if fingers.is_empty():
				touch_dragged = false
			fingers[event.index] = event.position
			touch_controls[event.index] = touch_target.call(event.position) if touch_target.is_valid() else null
			touch_dragged = touch_dragged or fingers.size() > 1
		elif fingers.has(event.index):
			fingers.erase(event.index)
			touch_controls.erase(event.index)
			if fingers.is_empty() and not touch_dragged and not event.canceled:
				var tap := InputEventMouseButton.new()
				tap.position = event.position
				tap.button_index = MOUSE_BUTTON_LEFT
				tap.pressed = true
				var release := tap.duplicate() as InputEventMouseButton
				release.pressed = false
				get_viewport().call_deferred("push_input", tap, true)
				get_viewport().call_deferred("push_input", release, true)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenDrag and fingers.has(event.index):
		var old: Vector2 = fingers[event.index]
		if fingers.size() == 1:
			if touch_dragged or old.distance_to(event.position) >= 7.0:
				var control: Control = touch_controls[event.index]
				if control is ScrollContainer:
					control.scroll_vertical += roundi(old.y - event.position.y)
				elif control == null:
					goal -= (event.position - old) / zoom
				fingers[event.index] = event.position
				touch_dragged = true
		else:
			for other in fingers:
				if other != event.index and touch_controls[other] == null and touch_controls[event.index] == null:
					var anchor: Vector2 = fingers[other]
					var distance := old.distance_to(anchor)
					if distance > 4.0:
						shift_zoom(event.position.distance_to(anchor) / distance)
					break
			fingers[event.index] = event.position
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_HOME:
		set_mode(1)
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			shift_zoom(1.18)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			shift_zoom(1.0 / 1.18)
