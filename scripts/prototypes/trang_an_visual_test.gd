extends Node2D

const ART := "res://assets/prototypes/trang_an/"
const SCENERY := "res://assets/"
const SIZE := Vector2(1600, 900)
const STOPS := [Vector2(85,602), Vector2(220,557), Vector2(355,502), Vector2(510,494),
	Vector2(645,482), Vector2(770,431), Vector2(905,444), Vector2(1037,500), Vector2(1130,535),
	Vector2(1225,543), Vector2(1303,585), Vector2(1354,624)]
var deck := PackedVector2Array([Vector2(1108,505), Vector2(1360,476), Vector2(1488,570), Vector2(1224,621)])
var promenade := Curve2D.new()
var route: Curve2D
var objects := Node2D.new()
var camera := Camera2D.new()
var stats := Label.new()
var guests: Array[Sprite2D] = []
var boats: Array[Sprite2D] = []
var wakes: Array[Line2D] = []
var passengers: Array[Array] = []
var paving: ArrayMesh
var paving_vertices := PackedVector2Array()
var paving_colors := PackedColorArray()
var stone_rng := RandomNumberGenerator.new()
var textures := {}
var elapsed := 0.0
var fps_elapsed := 0.0
var fps_frames := 0
var view := 0
var dragging := false

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var surface := Polygon2D.new()
	surface.polygon = PackedVector2Array([Vector2(-850,-550), Vector2(2450,-550), Vector2(2450,1450), Vector2(-850,1450)])
	var material := ShaderMaterial.new()
	material.shader = preload("res://assets/prototypes/trang_an/river.gdshader")
	surface.material = material
	surface.z_index = -3
	add_child(surface)
	for i in range(STOPS.size()):
		var previous: Vector2 = STOPS[maxi(0,i-1)]
		var next: Vector2 = STOPS[mini(STOPS.size()-1,i+1)]
		var tangent := (next-previous)*0.19
		promenade.add_point(STOPS[i], -tangent, tangent)
	route = promenade.duplicate()
	while promenade.point_count > 9:
		promenade.remove_point(promenade.point_count-1)
	add_child(objects)
	objects.y_sort_enabled = true
	populate()
	add_child(camera)
	camera.make_current()
	get_viewport().size_changed.connect(func(): set_view(view))
	hud()
	set_view(0)

func plant(file: String, position_at_foot: Vector2, width: float, depth := 0) -> Sprite2D:
	var path := (ART if file.ends_with(".svg") else SCENERY) + file
	if not textures.has(path):
		textures[path] = load(path)
	var sprite := Sprite2D.new()
	sprite.texture = textures[path]
	sprite.scale = Vector2.ONE * width / sprite.texture.get_width()
	sprite.offset.y = sprite.texture.get_height() * -0.40
	sprite.position = position_at_foot
	sprite.z_index = depth
	objects.add_child(sprite)
	return sprite

func populate() -> void:
	for item in [[Vector2(55,307),440],[Vector2(350,285),530],[Vector2(650,272),468],
		Vector2(940,270),Vector2(1210,259),Vector2(1515,320)]:
		if item is Array:
			plant("terrain/terrain_limestone_cliff_large.png",item[0],item[1],-2)
		else:
			plant("terrain/terrain_limestone_cliff_medium.png",item,440,-2)
	for item in [[135,374,227],[254,370,177],[379,321,186],[499,356,247],
		[646,349,186],[746,318,222],[875,344,226],[1007,364,207],[1136,334,238],
		[1262,363,209],[1401,356,223],[1559,428,228],[64,560,193]]:
		plant("nature/nature_tree_large_0%d.png" % (1 + int(item[0]) % 2),Vector2(item[0],item[1]),item[2])
	for point: Vector2 in [Vector2(156,430),Vector2(385,410),Vector2(681,403),
		Vector2(801,370),Vector2(968,407),Vector2(1151,422),Vector2(1459,432)]:
		plant("nature/nature_flowering_tree.png",point,147)
	for center: Vector2 in [Vector2(119,540),Vector2(324,550),Vector2(429,430),Vector2(562,547),
		Vector2(687,542),Vector2(795,502),Vector2(914,509),Vector2(990,556),Vector2(1052,441),
		Vector2(1156,465),Vector2(1438,463),Vector2(1474,526),Vector2(1550,477)]:
		plant("nature/nature_bush_green.png",center,106)
		plant("nature/nature_bush_flower_pink.png",center+Vector2(-30,12),71)
		plant("nature/nature_bush_flower_yellow.png",center+Vector2(29,7),65)
	for center: Vector2 in [Vector2(260,626),Vector2(385,593),Vector2(540,611),
		Vector2(689,578),Vector2(836,546),Vector2(1464,492)]:
		plant("nature/nature_bush_green.png",center,112)
		plant("nature/nature_rock_mossy.png",center+Vector2(33,4),58)
		plant("nature/nature_bush_flower_yellow.png",center+Vector2(-27,7),72)
	for x in range(24,1600,43):
		if x > 1070 and x < 1480:
			continue
		var y := shore(float(x))
		plant("nature/nature_rock_mossy.png",Vector2(x,y+2),56+float(x%25))
		if x % 3 != 0:
			plant("nature/nature_bush_green.png",Vector2(x-9,y-16),53+float(x%21))
		if x % 4 == 0:
			plant("nature/nature_lily_pad_cluster.png",Vector2(x+21,y+41),71)
	for item in [["prop_street_lamp",Vector2(350,481),66],["prop_street_lamp",Vector2(665,446),66],
		["prop_street_lamp",Vector2(941,470),65],["prop_street_lamp",Vector2(1076,508),61],
		["prop_direction_sign",Vector2(735,483),68],["prop_wooden_bench",Vector2(871,393),77],
		["prop_wooden_bench",Vector2(1059,465),73]]:
		plant("props/" + item[0] + ".png",item[1],item[2])
	plant("gate-quality2.svg",Vector2(229,539),268)
	plant("ticket-quality2.svg",Vector2(528,470),225)
	plant("landing-quality2.svg",Vector2(1246,531),252)
	signboard("CỔNG TRÀNG AN",Vector2(231,449))
	signboard("QUẦY VÉ  ·  150k",Vector2(539,407))
	signboard("BẾN THUYỀN TRÀNG AN",Vector2(1250,451))
	for i in range(16):
		var file := "character_tourist_female_idle" if i % 2 == 0 else "character_tourist_male_idle"
		var guest := plant("characters/" + file + ".png",STOPS[0],31)
		guests.append(guest)
	for i in range(3):
		var wake := Line2D.new()
		wake.width = 2.5
		wake.default_color = Color(0.67,0.96,0.86,0.72)
		wake.points = PackedVector2Array([Vector2(-12,2),Vector2(-38,9),Vector2(-65,11),Vector2(-93,20)])
		objects.add_child(wake)
		wakes.append(wake)
		boats.append(plant("vehicles/vehicle_tourist_boat_" + ("empty.png" if i==1 else "with_canopy.png"),Vector2.ZERO,120))
	for i in range(3):
		var crew: Array[Sprite2D] = []
		for j in range(3):
			var person := plant("characters/character_tourist_female_idle.png" if j==1 else "characters/character_tourist_male_idle.png",Vector2.ZERO,20)
			person.modulate = Color("#ffd19b")
			crew.append(person)
		passengers.append(crew)
	animate_world(0.0)

func signboard(title: String, center: Vector2) -> void:
	var plate := Label.new()
	plate.text = title
	plate.add_theme_font_size_override("font_size",13)
	plate.add_theme_color_override("font_color",Color("#ffe6a8"))
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#5e351d")
	style.border_color = Color("#d6aa57")
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	style.content_margin_left = 9
	style.content_margin_right = 9
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	plate.add_theme_stylebox_override("normal",style)
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.position = center - plate.get_minimum_size()/2.0
	plate.z_index = 2
	add_child(plate)

func shore(x: float) -> float:
	return 705.0-x*0.109+30.0*sin((x-170.0)*0.005)+16.0*sin(x*0.011)

func _draw() -> void:
	paving_vertices.clear()
	paving_colors.clear()
	stone_rng.seed = 124
	var length := promenade.get_baked_length()
	var rows := ceili(length/13.0)
	for i in range(rows):
		var a := promenade.sample_baked(length*i/rows)
		var b := promenade.sample_baked(length*(i+1)/rows)
		var normal := (b-a).normalized().orthogonal()
		var width := 39.0 + 17.0 * exp(-pow((a.x-508.0)/125.0,2.0)) + 10.0 * exp(-pow((a.x-227.0)/140.0,2.0))
		var edge := normal * width * 0.88
		paving_quad(a-edge,a+edge,b+edge,b-edge,Color("#8a7351"))
		var left := -0.98
		for j in range(6):
			var right := 0.98 if j==5 else -1.0+(j+1)*0.333+stone_rng.randf_range(-0.075,0.075)
			var tint := Color("#e8d1a8").lerp(Color("#aa946e"),stone_rng.randf())
			paving_quad(a.lerp(b,0.05)+edge*(left+0.013),
				a.lerp(b,0.05)+edge*(right-0.013),b.lerp(a,0.07)+edge*(right-0.013),
				b.lerp(a,0.07)+edge*(left+0.013),tint)
			left = right
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = paving_vertices
	arrays[Mesh.ARRAY_COLOR] = paving_colors
	paving = ArrayMesh.new()
	paving.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays,[],{},Mesh.ARRAY_FLAG_USE_2D_VERTICES)
	var spine := promenade.get_baked_points()
	draw_polyline(spine,Color("#6f7750"),99.0,true)
	draw_polyline(spine,Color("#9d8c68"),91.0,true)
	draw_mesh(paving,null)
	draw_colored_polygon(deck,Color("#674629"))
	for i in range(32):
		var start := deck[0].lerp(deck[1],float(i)/32.0)
		var end := deck[3].lerp(deck[2],float(i)/32.0)
		var start_next := deck[0].lerp(deck[1],(i+0.90)/32.0)
		var end_next := deck[3].lerp(deck[2],(i+0.90)/32.0)
		draw_colored_polygon(PackedVector2Array([start,start_next,end_next,end]),
			Color("#dda773").lerp(Color("#a96f43"),stone_rng.randf()))
	draw_line(Vector2(1311,586),Vector2(1355,626),Color("#9c653d"),32)
	for i in range(7):
		var stair := Vector2(1312,586).lerp(Vector2(1355,626),i/6.0)
		draw_line(stair+Vector2(-15,4),stair+Vector2(15,-4),Color("#dfae78"),5)
	rail(deck[3],Vector2(1305,605),5)
	rail(Vector2(1360,594),deck[2],6)
	rail(deck[1],deck[2],6)
	rail(Vector2(450,521),Vector2(611,500),7,true)
	rail(Vector2(1115,541),Vector2(1254,526),6,true)

func paving_quad(a: Vector2, b: Vector2, c: Vector2, d: Vector2, tint: Color) -> void:
	paving_vertices.append_array(PackedVector2Array([a,b,c,a,c,d]))
	for i in range(6):
		paving_colors.append(tint)

func rail(from: Vector2, to: Vector2, count: int, rope := false) -> void:
	var post_height := 12.0 if rope else 25.0
	for i in range(count):
		var post := from.lerp(to,float(i)/(count-1))
		draw_line(post+Vector2(0,0 if rope else 19),post-Vector2(0,post_height),
			Color("#624529"),4 if rope else 8,true)
		draw_circle(post-Vector2(0,post_height),2.5,Color("#e0af69"))
		if i>0:
			var previous := from.lerp(to,float(i-1)/(count-1))-Vector2(0,post_height-4)
			var end := post-Vector2(0,post_height-4)
			if rope:
				draw_polyline(PackedVector2Array([previous,(previous+end)/2+Vector2(0,4),end]),Color("#9b3528"),3,true)
			else:
				draw_line(previous,end,Color("#ca8b56"),5,true)

func animate_world(delta: float) -> void:
	elapsed += delta
	var length := route.get_baked_length()
	for i in range(guests.size()):
		var t := fposmod(elapsed+i*3.25,65.0)
		var dist := 0.0
		if t < 13:
			dist = 390.0*t/13.0
		elif t < 19:
			dist = 390.0
		elif t < 35:
			dist = lerpf(390.0,length-114.0,(t-19.0)/16.0)
		elif t < 41:
			dist = length-114.0
		elif t < 46:
			dist = lerpf(length-114.0,length,(t-41.0)/5.0)
		elif t > 50:
			dist = length*(65.0-t)/15.0
		var guest := guests[i]
		guest.visible = t < 46.0 or t >= 50.0
		var waiting := (t>=13.0 and t<19.0) or (t>=35.0 and t<41.0)
		var slot := float(i%4)
		if waiting:
			dist -= slot*11.0
		guest.position = route.sample_baked(dist)+Vector2(0,(i%3-1)*6.0)
		guest.offset.y = -guest.texture.get_height()*0.40 + (0.0 if waiting else sin(t*14.0)*3.0)
		guest.flip_h = t >= 50.0
	for i in range(boats.size()):
		var phase := elapsed*0.12+i*2.1
		var position := Vector2(1205.0+i*75.0+sin(phase)*145.0,650.0+i*67.0+(1.0-cos(phase))*36.0)
		var moving_right := cos(phase)>0.0
		boats[i].position = position
		boats[i].flip_h = not moving_right
		wakes[i].position = position-Vector2(0,5)
		wakes[i].scale.x = 1.0 if moving_right else -1.0
		for j in range(passengers[i].size()):
			var person: Sprite2D = passengers[i][j]
			person.position = position + Vector2((j-1)*16.0,-6.0)
			person.flip_h = not moving_right

func hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var controls := HBoxContainer.new()
	controls.position = Vector2(18,15)
	layer.add_child(controls)
	for i in range(3):
		var button := Button.new()
		button.text = ["Toàn cảnh / Đặt lại","Quầy vé","Bến thuyền"][i]
		button.custom_minimum_size = Vector2(105,35)
		button.pressed.connect(set_view.bind(i))
		controls.add_child(button)
	stats.add_theme_font_size_override("font_size",14)
	controls.add_child(stats)
	var hint := Label.new()
	hint.position = Vector2(20,55)
	hint.text = "TRÀNG AN · VISUAL TEST V0.4     |     Kéo chuột giữa · Cuộn để zoom · Home"
	hint.add_theme_color_override("font_shadow_color",Color.BLACK)
	hint.add_theme_constant_override("shadow_offset_y",2)
	layer.add_child(hint)

func set_view(index: int) -> void:
	view = index
	var fit := minf(get_viewport_rect().size.x/SIZE.x,get_viewport_rect().size.y/SIZE.y)
	camera.position = [Vector2(800,450),Vector2(470,449),Vector2(1240,560)][index]
	camera.zoom = Vector2.ONE * fit * [1.0,2.0,1.85][index]

func _process(delta: float) -> void:
	animate_world(delta)
	fps_elapsed += delta
	fps_frames += 1
	if fps_elapsed >= 1.0:
		stats.text = "   %.0f FPS  /  %.1f ms" % [fps_frames/fps_elapsed,1000.0*fps_elapsed/fps_frames]
		fps_elapsed = 0.0
		fps_frames = 0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_HOME:
		set_view(0)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			dragging = event.pressed
		elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			var factor := 1.12 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0/1.12
			camera.zoom = Vector2.ONE*clampf(camera.zoom.x*factor,0.35,3.8)
	if event is InputEventMouseMotion and dragging:
		camera.position -= event.relative/camera.zoom
