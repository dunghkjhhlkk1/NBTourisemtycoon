class_name BoatController
extends Node

var world: WorldManager
var route := PackedVector2Array()
var fleet := {}
var occupied_texture: Texture2D = preload("res://assets/vehicles/vehicle_tourist_boat_with_canopy.png")
var texture: Texture2D = preload("res://assets/vehicles/vehicle_tourist_boat_empty.png")

func setup(map: WorldManager, scenic := false) -> void:
	world = map
	if scenic:
		for point: Array in world.ground.boat_route:
			route.append(world.project(Vector2(float(point[0]), float(point[1]))))
		return
	for x in range(27, 40):
		var y := 32.0 + 2.4 * sin((float(x) - 24.0) * 0.2)
		route.append(world.project(Vector2(float(x), y)))

func render(instances: Dictionary, fraction := 0.0) -> void:
	for id: int in fleet.keys():
		if not instances.has(id):
			fleet[id].queue_free()
			fleet.erase(id)
	for service: Dictionary in instances.values():
		if service.kind != "dock":
			continue
		if not fleet.has(service.id):
			var sprite := Sprite2D.new()
			sprite.texture = texture
			sprite.scale = Vector2.ONE * 91.0 / texture.get_width()
			world.objects.add_child(sprite)
			var wake := Line2D.new()
			wake.name = "Wake"
			wake.show_behind_parent = true
			wake.default_color = Color(0.73, 0.98, 0.90, 0.65)
			wake.width = 13
			wake.antialiased = true
			sprite.add_child(wake)
			fleet[service.id] = sprite
		var craft: Sprite2D = fleet[service.id]
		craft.texture = occupied_texture if service.remaining > 0 else texture
		craft.scale = Vector2.ONE * 112.0 / craft.texture.get_width()
		var progress := 1.0 - maxf(0.0, float(service.remaining) - fraction) / float(service.spec.duration)
		var along := (1.0 - absf(progress * 2.0 - 1.0)) * (route.size() - 1)
		var index := mini(int(along), route.size() - 2)
		fleet[service.id].position = route[index].lerp(route[index + 1], along - index)
		fleet[service.id].flip_h = progress > 0.5


		var wake: Line2D = craft.get_node("Wake")
		wake.visible = service.remaining > 0
		if wake.visible:
			var tail := -1.0 if progress <= 0.5 else 1.0
			wake.points = PackedVector2Array([Vector2(tail * 280, 38), Vector2(tail * 560, 61), Vector2(tail * 880, 54)])