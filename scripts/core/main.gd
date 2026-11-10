extends Node2D

var world: WorldManager
var buildings: BuildingManager
var camera: CameraController
var builder: ConstructionController
var paths: PathfindingManager
var visitors: VisitorController
var boats: BoatController
var ui: UIManager
var district

func _ready() -> void:
	world = WorldManager.new()
	add_child(world)
	buildings = BuildingManager.new()
	add_child(buildings)
	var business_mode := not "--offline-v02" in OS.get_cmdline_user_args()
	buildings.presentation_scale = 1.48 if business_mode else 1.0
	buildings.setup(world)
	paths = PathfindingManager.new()
	paths.world = world
	paths.buildings = buildings
	camera = CameraController.new()
	camera.business_view = business_mode
	add_child(camera)
	builder = ConstructionController.new()
	builder.world = world
	builder.manager = buildings
	builder.z_index = 10
	add_child(builder)
	visitors = VisitorController.new()
	visitors.world = world
	visitors.paths = paths
	visitors.z_index = 9
	add_child(visitors)
	buildings.changed.connect(visitors.invalidate)
	boats = BoatController.new()
	add_child(boats)
	boats.setup(world, business_mode)
	decorate()
	if business_mode:
		district = preload("res://scripts/world/district_presentation.gd").new()
		world.add_child(district)
		district.setup(world)
		decorate_business_district()
	ui = UIManager.new()
	add_child(ui)
	visitors.boats = boats
	visitors.invalidate()
	builder.simulation = visitors
	ui.simulation = visitors
	if not "--offline-v02" in OS.get_cmdline_user_args():
		var properties = preload("res://scripts/core/property_client.gd").new()
		properties.world = world
		properties.district = district
		properties.buildings = buildings
		properties.z_index = 8
		add_child(properties)
		visitors.server_economy = true
		builder.properties = properties
		ui.properties = properties
	ui.setup(buildings,builder,camera)
	buildings.may_remove = func(record: Dictionary) -> bool:
		if builder.properties != null:
			ui.show_status("Tháo dỡ tài sản đang khóa trong phiên kinh doanh.")
			return false
		var service: Dictionary = visitors.services.instances.get(record.sprite.get_instance_id(), {})
		if not service.is_empty() and not service.groups.is_empty():
			ui.show_status("Hãy đợi phục vụ xong trước khi xóa.")
			return false
		return true


func decorate() -> void:
	var decor := [
		["props/prop_direction_sign",Vector2(10.9,23.4),43],
		["props/prop_street_lamp",Vector2(15.6,23.7),57],
		["props/prop_street_lamp",Vector2(22.5,23.6),57],
		["props/prop_wooden_bench",Vector2(18.7,23.7),62],
		["props/prop_wooden_bench",Vector2(27.7,23.7),62],
		["props/prop_flower_pot",Vector2(22.4,22.6),31],
		["nature/nature_flowering_tree",Vector2(21.9,19.3),155],
		["nature/nature_tree_large_01",Vector2(13.8,20.1),190],
		["nature/nature_tree_large_02",Vector2(34.4,22.8),137],
		["nature/nature_tree_small",Vector2(26.1,19.5),88],
		["nature/nature_bamboo_cluster",Vector2(31.7,18.8),108],
		["nature/nature_bush_green",Vector2(33.1,23.3),68],
		["nature/nature_bush_flower_yellow",Vector2(33.4,28.6),72],
		["terrain/terrain_limestone_cliff_large",Vector2(23.0,16.0),380],
		["terrain/terrain_limestone_cliff_medium",Vector2(26.5,15.1),260],
		["terrain/terrain_limestone_cliff_small",Vector2(34.7,27.0),120],
		["terrain/terrain_limestone_rock_cluster",Vector2(29.8,30.2),100],
		["nature/nature_rock_mossy",Vector2(32.4,30.7),52],
		["nature/nature_lotus_pink",Vector2(29.1,33.0),42],
		["nature/nature_lotus_pink",Vector2(36.1,33.2),35],
		["nature/nature_lily_pad_cluster",Vector2(30.1,33.4),57],
		["nature/nature_lily_pad_cluster",Vector2(35.8,34.1),48]
	]
	for item: Array in decor:
		world.decorate(item[0],item[1],item[2])
	var random := RandomNumberGenerator.new()
	random.seed = 16026
	for index in range(65):
		var cell := Vector2(random.randf_range(2,46),random.randf_range(2,46))
		if Rect2(11,17,25,14).has_point(cell) or world.water_cells.has(Vector2i(cell.floor())) or world.road_cells.has(Vector2i(cell.floor())):
			continue
		var file: String = ["nature/nature_tree_large_01","nature/nature_tree_small","nature/nature_bush_green"][index % 3]
		world.decorate(file,cell,[150,75,59][index % 3])

func decorate_business_district() -> void:
	var items := [
		["props/prop_direction_sign", Vector2(10.3,23.1), 58],
		["props/prop_flower_pot", Vector2(18.4,22.9), 33],
		["props/prop_flower_pot", Vector2(27.3,23.5), 32],
		["props/prop_wooden_bench", Vector2(28.6,25.5), 57],
		["props/prop_street_lamp", Vector2(30.5,26.8), 57],
		["props/prop_direction_sign", Vector2(32.4,28.7), 56],
		["nature/nature_bush_flower_yellow", Vector2(30.1,29.6), 49],
		["nature/nature_flowering_tree", Vector2(34.4,25.4), 118],
		["nature/nature_bush_green", Vector2(30.8,23.1), 47],
		["nature/nature_bush_flower_yellow", Vector2(26.7,23.3), 41],
		["nature/nature_tree_small", Vector2(22.4,21.8), 77],
		["nature/nature_bush_green", Vector2(19.2,22.0), 46]
	]
	for item: Array in items:
		world.decorate(item[0], item[1], item[2])