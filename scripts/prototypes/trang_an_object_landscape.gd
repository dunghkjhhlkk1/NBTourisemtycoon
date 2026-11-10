extends Node2D

const ASSETS := "res://assets/"
const BANK := [Vector2(-60, 744), Vector2(140, 724), Vector2(318, 671), Vector2(487, 618),
	Vector2(610, 575), Vector2(811, 548), Vector2(1074, 520), Vector2(1234, 465),
	Vector2(1292, 378), Vector2(1228, 272), Vector2(1210, 132), Vector2(1310, -70)]
const DECK := [Vector2(506, 551), Vector2(1170, 401), Vector2(1325, 485), Vector2(595, 642)]
var random := RandomNumberGenerator.new()

func _ready() -> void:
	random.seed = 274
	var water := Polygon2D.new()
	water.name = "River"
	water.polygon = PackedVector2Array([Vector2(-160,-120),Vector2(1840,-120),Vector2(1840,1080),Vector2(-160,1080)])
	var material := ShaderMaterial.new()
	material.shader = preload("res://assets/prototypes/trang_an/object-river.gdshader")
	water.material = material
	water.z_index = -4
	add_child(water)
	var ground := Polygon2D.new()
	ground.name = "LivingGround"
	ground.polygon = PackedVector2Array(BANK + [Vector2(-160,-100)])
	var ground_material := ShaderMaterial.new()
	ground_material.shader = preload("res://assets/prototypes/trang_an/object-land.gdshader")
	ground.material = ground_material
	ground.z_index = -3
	add_child(ground)
	var promenade := Node2D.new()
	promenade.name = "Promenade"
	promenade.draw.connect(draw_promenade.bind(promenade))
	add_child(promenade)
	var boardwalk := Node2D.new()
	boardwalk.name = "Boardwalk"
	boardwalk.draw.connect(draw_deck.bind(boardwalk))
	add_child(boardwalk)
	add_gardens()

func _draw() -> void:
	var shore := PackedVector2Array(BANK)
	draw_polyline(shore,Color("#416849"),28.0,true)
	draw_polyline(shore,Color("#a69b69"),14.0,true)
	draw_polyline(shore,Color("#73874d"),6.0,true)
	var far_bank := PackedVector2Array([Vector2(1530,-80),Vector2(1490,105),Vector2(1508,252),
		Vector2(1572,341),Vector2(1705,402),Vector2(1820,350),Vector2(1820,-80)])
	draw_colored_polygon(far_bank,Color("#465e31"))

func draw_promenade(layer: Node2D) -> void:
	# Stone terraces support each building and meet the connecting paths.
	terrace(layer, PackedVector2Array([Vector2(290,300),Vector2(496,275),Vector2(565,311),Vector2(348,344)]))
	terrace(layer, PackedVector2Array([Vector2(725,236),Vector2(839,217),Vector2(875,246),Vector2(762,268)]))
	terrace(layer, PackedVector2Array([Vector2(908,252),Vector2(1014,239),Vector2(1048,259),Vector2(939,278)]))
	draw_path(layer, [Vector2(-65,684),Vector2(115,614),Vector2(335,558),Vector2(495,370),
		Vector2(704,297),Vector2(823,285),Vector2(888,343),Vector2(807,422),Vector2(579,489),Vector2(506,552)])
	draw_path(layer, [Vector2(335,558),Vector2(375,519),Vector2(478,556),Vector2(565,556)])
	terrace(layer, PackedVector2Array([Vector2(151,510),Vector2(351,510),Vector2(357,544),Vector2(143,544)]))
	draw_path(layer, [Vector2(345,302),Vector2(409,328),Vector2(462,367)])
	draw_path(layer, [Vector2(770,244),Vector2(796,273),Vector2(822,291)])
	draw_path(layer, [Vector2(967,260),Vector2(923,282),Vector2(872,316)])

func terrace(layer: Node2D, area: PackedVector2Array) -> void:
	layer.draw_colored_polygon(PackedVector2Array([area[3],area[2],area[2]+Vector2(0,10),area[3]+Vector2(0,10)]),Color("#75634e"))
	layer.draw_colored_polygon(area, Color("#cbb691"))
	for step in range(4):
		var offset := Vector2(0,step*4)
		layer.draw_line(area[3]+offset,area[2]+offset,Color("#eee0c0"),1.5,true)
func draw_path(layer: Node2D, points: Array) -> void:
	var route := Curve2D.new()
	for i in range(points.size()):
		var tangent: Vector2 = (points[mini(i+1,points.size()-1)]-points[maxi(i-1,0)])*0.18
		route.add_point(points[i],-tangent,tangent)
	layer.draw_polyline(route.get_baked_points(),Color("#77784b"),72,true)
	layer.draw_polyline(route.get_baked_points(),Color("#a18b6b"),65,true)
	var rng := RandomNumberGenerator.new()
	rng.seed = 583
	var distance := route.get_baked_length()
	for step in range(ceili(distance/15.0)):
		var at := step*15.0
		var a := route.sample_baked(at)
		var b := route.sample_baked(minf(at+14.5,distance))
		var normal := (b-a).normalized().orthogonal()
		for column in range(4):
			var shift := float(column)*15.5-30.0
			var side := normal*shift
			var edge := normal*14.6
			var uneven := (b-a)*rng.randf_range(-0.15,0.15)
			layer.draw_colored_polygon(PackedVector2Array([a+side+uneven,a+side+edge,b+side+edge-uneven,b+side]),
				Color("#f0d6a8").lerp(Color("#a69172"),rng.randf()))

func draw_deck(layer: Node2D) -> void:
	layer.draw_colored_polygon(PackedVector2Array([DECK[3],DECK[2],DECK[2]+Vector2(0,18),DECK[3]+Vector2(0,18)]),Color("#513826"))
	layer.draw_colored_polygon(PackedVector2Array(DECK),Color("#805331"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 8
	for index in range(56):
		var from := index/56.0
		var to := (index+0.94)/56.0
		layer.draw_colored_polygon(PackedVector2Array([DECK[0].lerp(DECK[1],from),DECK[0].lerp(DECK[1],to),
			DECK[3].lerp(DECK[2],to),DECK[3].lerp(DECK[2],from)]),Color("#e3b37a").lerp(Color("#a56e3b"),rng.randf()))
		if index % 2 == 0:
			var grain_start: Vector2 = DECK[0].lerp(DECK[1],from).lerp(DECK[3].lerp(DECK[2],from),0.27)
			var grain_end: Vector2 = DECK[0].lerp(DECK[1],to).lerp(DECK[3].lerp(DECK[2],to),0.72)
			layer.draw_line(grain_start,grain_end,Color("#65452c52"),1.0,true)
	for i in range(17):
		var t := i/16.0
		if t > 0.64 and t < 0.81:
			continue
		var post: Vector2 = DECK[3].lerp(DECK[2],t)
		layer.draw_line(post+Vector2(0,25),post-Vector2(0,23),Color("#58351f"),8,true)
		layer.draw_line(post+Vector2(-2,12),post+Vector2(-2,-23),Color("#d29a56"),2,true)
	for segment in [Vector2(0.0,0.64),Vector2(0.81,1.0)]:
		for height in [8.0,20.0]:
			var offset := Vector2(0,-height)
			layer.draw_line(DECK[3].lerp(DECK[2],segment.x)+offset,DECK[3].lerp(DECK[2],segment.y)+offset,Color("#dcad68"),4,true)
	for t in [0.19, 0.49, 0.9]:
		var ring: Vector2 = DECK[3].lerp(DECK[2],t)+Vector2(0,-12)
		layer.draw_arc(ring,10.0,0,TAU,24,Color("#fff0d2"),4.0,true)
		layer.draw_arc(ring,10.0,0.55,1.26,8,Color("#cc4826"),4.0,true)
		layer.draw_arc(ring,10.0,3.65,4.36,8,Color("#cc4826"),4.0,true)
	for i in range(7):
		var start := Vector2(1050,551)+Vector2(9,5)*i
		layer.draw_line(start,start+Vector2(103,-22),Color("#6f462c"),9,true)
		layer.draw_line(start-Vector2(0,2),start+Vector2(103,-24),Color("#dfb37b"),4,true)

func add_gardens() -> void:
	var cliffs := "terrain/terrain_limestone_cliff_large.png"
	for spec in [[Vector2(88,215),440],[Vector2(409,188),490],[Vector2(717,177),480],
		[Vector2(1042,196),470],[Vector2(1531,231),410],[Vector2(1715,353),376]]:
		prop(cliffs,spec[0],spec[1])
	for pos: Vector2 in [Vector2(80,240), Vector2(322,218), Vector2(570,211),
		Vector2(854,215), Vector2(1055,230), Vector2(1515,269), Vector2(1650,367)]:
		prop("terrain/terrain_limestone_rock_cluster.png",pos,random.randf_range(95,155))
		prop("nature/nature_bush_green.png",pos+Vector2(34,9),random.randf_range(66,98))
		prop("nature/nature_bamboo_cluster.png",pos+Vector2(-38,-6),random.randf_range(70,105))
	# A low, irregular band of roots, grasses and stone breaks the cliff silhouettes.
	for pos: Vector2 in [Vector2(19,289),Vector2(143,258),Vector2(275,253),Vector2(391,236),
		Vector2(509,256),Vector2(641,224),Vector2(771,235),Vector2(909,231),
		Vector2(1116,237),Vector2(1438,300),Vector2(1605,327)]:
		prop("nature/nature_rock_mossy.png",pos,random.randf_range(52,89))
		prop("nature/nature_bush_green.png",pos+Vector2(28,-4),random.randf_range(63,96))
	for pos: Vector2 in [Vector2(101,390),Vector2(230,319),Vector2(575,246),Vector2(656,259),
		Vector2(826,211),Vector2(986,231),Vector2(1136,273),Vector2(1519,198),Vector2(1648,323)]:
		prop("nature/nature_tree_large_0%d.png" % (1 + random.randi_range(0,1)),pos,random.randf_range(158,241))
	for pos: Vector2 in [Vector2(163,290),Vector2(329,202),Vector2(643,328),Vector2(900,290),
		Vector2(1116,383),Vector2(1493,270),Vector2(1584,365)]:
		prop("nature/nature_flowering_tree.png",pos,random.randf_range(102,172))
	for pos: Vector2 in [Vector2(50,647),Vector2(153,594),Vector2(288,567),Vector2(381,591),
		Vector2(426,471),Vector2(536,429),Vector2(637,442),Vector2(788,403),Vector2(1060,419),
		Vector2(1182,414),Vector2(1235,440),Vector2(1548,376),Vector2(1662,398)]:
		prop("nature/nature_bush_green.png",pos,random.randf_range(83,125))
		prop("nature/nature_bush_flower_pink.png",pos+Vector2(-27,9),random.randf_range(51,80))
		prop("nature/nature_bush_flower_yellow.png",pos+Vector2(26,15),random.randf_range(49,70))
	# Garden beds border the path and dock entrance; the walking corridor stays open.
	for pos: Vector2 in [Vector2(360,462),Vector2(399,440),Vector2(441,426),
		Vector2(577,347),Vector2(626,331),Vector2(671,319),
		Vector2(732,392),Vector2(803,396),Vector2(1089,361),Vector2(1184,390)]:
		prop("nature/nature_bush_flower_pink.png",pos,random.randf_range(53,83))
		prop("nature/nature_bush_green.png",pos+Vector2(18,10),random.randf_range(52,82))
	for pos: Vector2 in [Vector2(410,403),Vector2(597,321),Vector2(854,330),Vector2(1180,374)]:
		prop("props/prop_street_lamp.png",pos,random.randf_range(77,102))
	for pos: Vector2 in [Vector2(426,399),Vector2(704,345),Vector2(1120,391)]:
		prop("props/prop_wooden_bench.png",pos,random.randf_range(80,105))
	prop("props/prop_direction_sign.png",Vector2(536,384),78)
	for pos: Vector2 in [Vector2(520,582),Vector2(548,579),Vector2(576,580),Vector2(608,574),Vector2(637,568),
		Vector2(1190,437),Vector2(1220,420),Vector2(1252,399),Vector2(1272,368),Vector2(1264,339),
		Vector2(1250,306),Vector2(1232,275)]:
		prop("nature/nature_rock_mossy.png",pos,random.randf_range(45,75))
		prop("nature/nature_bush_green.png",pos+Vector2(-7,-12),random.randf_range(32,58))
	for i in range(24):
		var t := i/24.0
		var x := lerpf(0,525,t)
		var y := lerpf(732,607,t)+random.randf_range(-12,13)
		prop("nature/nature_rock_mossy.png",Vector2(x,y),random.randf_range(38,77))
	for pos: Vector2 in [Vector2(315,715),Vector2(480,695),Vector2(680,801),Vector2(1469,542),Vector2(1361,556)]:
		prop("nature/nature_lily_pad_cluster.png",pos,random.randf_range(49,89))
	for pos: Vector2 in [Vector2(127,924),Vector2(1160,945),Vector2(1298,893),Vector2(1478,867),Vector2(1664,820)]:
		prop("nature/nature_tree_large_02.png",pos+Vector2(55,130),random.randf_range(216,314),5)
		prop("nature/nature_bush_flower_pink.png",pos,random.randf_range(85,147),5)

func prop(file: String, point: Vector2, width: float, depth := 0) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = load(ASSETS+file)
	sprite.scale = Vector2.ONE*width/sprite.texture.get_width()
	sprite.offset.y = -sprite.texture.get_height()*0.39
	sprite.position = point
	sprite.z_index = depth
	add_child(sprite)
