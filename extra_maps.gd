extends RefCounted
# Original arenas inspired by voxel villages and dense battle-royale city blocks.
var world: Node3D
func build(scene: Node3D, level: int) -> void:
	world = scene
	if level == 1:
		valley()
		valley_landmarks()
	else:
		city()
		city_landmarks()
	for side in [-1,1]:
		b("ArenaWall",Vector3(1,5,65),Vector3(side*30,2.5,0),"795637" if level == 1 else "8b887b")
		b("ArenaWall",Vector3(60,5,1),Vector3(0,2.5,side*32),"795637" if level == 1 else "8b887b")
	var shops = world.get_node("Vendors").vendors
	shops[0].position = Vector3(-10,0,-25)
	shops[1].position = Vector3(10,0,25)
	for pos in [Vector3(-10,0,-25),Vector3(10,0,25)]:
		b("ShopAwning",Vector3(4,0.25,3),pos+Vector3(0,3,0),"d99b42")
		for x in [-1.8,1.8]:
			b("ShopPost",Vector3(.16,3,.16),pos+Vector3(x,1.5,1),"684c32")
		world.label("SUPPLIES",pos+Vector3(0,3.35,0),0,32)
func b(n: String, s: Vector3, p: Vector3, c: String, solid: bool = true) -> Node3D:
	var body = world.box(n,s,p,c,solid)
	var kind = ""
	if n in ["VoxelGround","GrassTile","CliffGrass","OakLeaves","OakCrown"]:
		kind = "grass"
	elif n in ["TimberWall","FrontWall","SteppedRoof"]:
		kind = "planks"
	elif n in ["DirtCliff"]:
		kind = "dirt"
	elif n in ["CobbleBase","Chimney","WellRim"]:
		kind = "stone"
	elif n in ["BuildingSide","BuildingFront","UpperFacade","ClockTower"]:
		kind = "brick"
	if kind != "":
		for child in body.get_children():
			if child is MeshInstance3D:
				child.material_override = surface(kind,c)
	return body

var surfaces: Dictionary = {}
func surface(kind: String, color: String) -> StandardMaterial3D:
	var key = kind+color
	if surfaces.has(key):
		return surfaces[key]
	var img = Image.create(32,32,false,Image.FORMAT_RGB8)
	var rng = RandomNumberGenerator.new()
	rng.seed = 792
	var base = Color(color)
	for y in range(32):
		for x in range(32):
			var shade = rng.randf_range(.92,1.06)
			if kind == "planks" and (y%8 == 0 or (x+(y/8 as int)*9)%24 == 0):
				shade = .57
			if kind == "brick" and (y%8 == 0 or (x+(y/8 as int)*8)%16 == 0):
				shade = 1.28
			if kind == "stone" and (y%8 == 0 or (x+(y/8 as int)*5)%11 == 0):
				shade = .55
			img.set_pixel(x,y,Color(base.r*shade,base.g*shade,base.b*shade))
	var mat = StandardMaterial3D.new()
	mat.albedo_texture = ImageTexture.create_from_image(img)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.uv1_triplanar = true
	mat.uv1_scale = Vector3.ONE * .25
	mat.roughness = .9
	surfaces[key] = mat
	return mat
func valley() -> void:
	b("VoxelGround",Vector3(60,1,64),Vector3(0,-.5,0),"6ea443")
	for x in range(-28,30,2):
		for z in range(-30,32,2):
			if (x*13+z*7)%5 == 0:
				b("GrassTile",Vector3(2,.015,2),Vector3(x,.01,z),"79b34c",false)
	for z in [-7,7]:
		b("VillagePath",Vector3(58,.03,3),Vector3(0,.02,z),"bba270",false)
	b("VillagePath",Vector3(4,.03,60),Vector3(0,.02,0),"bba270",false)
	for x in [-13,13]:
		for z in [-17,17]:
			cottage(Vector3(x,0,z))
	for pos in [Vector3(-23,0,-15),Vector3(23,0,15),Vector3(-22,0,19),Vector3(22,0,-19),Vector3(-8,0,2),Vector3(9,0,-2)]:
		b("OakTrunk",Vector3(.8,4,.8),pos+Vector3(0,2,0),"705031")
		b("OakLeaves",Vector3(4,2.6,4),pos+Vector3(0,4.4,0),"38703c")
		b("OakCrown",Vector3(2.6,1.5,2.6),pos+Vector3(0,6,0),"4d8a3f")
	# Low central well provides cover while leaving four routes through the village.
	for x in [-1,1]:
		b("WellRim",Vector3(.4,1.2,2.6),Vector3(x*1.2,.6,0),"828b88")
		b("WellPost",Vector3(.22,3,.22),Vector3(x*1.2,1.5,0),"795c37")
	b("WellWater",Vector3(2,.03,2),Vector3(0,.4,0),"46a8ce",false)
	b("WellCanopy",Vector3(3.5,.3,3.5),Vector3(0,3,0),"87623d")
	for side in [-1,1]:
		for i in range(5):
			b("FarmSoil",Vector3(1,.04,5),Vector3(side*(5+i),.03,side*24),"654832",false)
			for j in range(5):
				b("Wheat",Vector3(.4,.65,.4),Vector3(side*(5+i),.35,side*24-2+j),"d8c05e",false)
		for i in range(9):
			var height = 4+(i%3)*2
			b("DirtCliff",Vector3(7,height,7),Vector3(-32+i*8,height/2.0,side*37),"795637",false)
			b("CliffGrass",Vector3(7,.6,7),Vector3(-32+i*8,height,side*37),"629741",false)
	world.label("VOXEL VALLEY",Vector3(0,4,-31),0,64)
func cottage(p: Vector3) -> void:
	b("CobbleBase",Vector3(8,.14,7),p+Vector3(0,.07,0),"858981")
	b("TimberWall",Vector3(8,3.4,.35),p+Vector3(0,1.7,-3.5),"b59a61")
	for x in [-4,4]:
		b("TimberWall",Vector3(.35,3.4,7),p+Vector3(x,1.7,0),"b59a61")
		for z in [-3.5,3.5]:
			b("LogFrame",Vector3(.55,3.7,.55),p+Vector3(x,1.85,z),"684b2e")
	for x in [-2.8,2.8]:
		b("FrontWall",Vector3(2.4,3.4,.35),p+Vector3(x,1.7,3.5),"b59a61")
		b("WindowGlass",Vector3(1,1,.06),p+Vector3(x,2,3.71),"79b8c3",false)
	b("DoorLintel",Vector3(3.2,.6,.4),p+Vector3(0,3.1,3.5),"684b2e")
	for i in range(4):
		b("SteppedRoof",Vector3(9-i*2,.65,8),p+Vector3(0,3.65+i*.6,0),"78542f")
	b("Chimney",Vector3(1,2,1),p+Vector3(2,5,-1),"7c807b")
	b("InteriorCrate",Vector3(1.2,1.1,1.2),p+Vector3(-2, .65,-2),"947443")
func city() -> void:
	b("CityGround",Vector3(60,1,64),Vector3(0,-.5,0),"515b64")
	for x in [-14,14]:
		for z in [-17,17]:
			building(Vector3(x,0,z),3 if x*z>0 else 4,"a77d6c" if x<0 else "aab8bb")
	for z in range(-28,31,5):
		b("LaneStripe",Vector3(.16,.02,2.5),Vector3(0,.025,z),"e9d795",false)
	for x in range(-28,31,5):
		b("LaneStripe",Vector3(2.5,.02,.16),Vector3(x,.025,0),"e9d795",false)
	for x in [-6,6]:
		for z in [-8,8]:
			for i in range(5):
				b("Crosswalk",Vector3(.5,.025,2.5),Vector3(x-1.5+i*.75,.03,z),"d7d9cf",false)
	# Clock tower is offset from the central crossroads so every street stays connected.
	var t = Vector3(22,0,2)
	b("ClockTower",Vector3(4,12,4),t+Vector3(0,6,0),"b7aa91")
	for h in [1,8,11.6]:
		b("TowerCornice",Vector3(4.5,.3,4.5),t+Vector3(0,h,0),"e0d7bb")
	b("TowerCap",Vector3(5,.5,5),t+Vector3(0,12.2,0),"485b61")
	for side in [-1,1]:
		b("ClockFace",Vector3(2.5,2.5,.08),t+Vector3(0,9.7,side*2.05),"ede7d2",false)
		b("ClockHand",Vector3(.13,.9,.1),t+Vector3(0,10,side*2.12),"333e45",false)
		b("ClockHand",Vector3(.7,.13,.1),t+Vector3(.28,9.6,side*2.12),"333e45",false)
	for pos in [Vector3(-11,0,2),Vector3(8,0,-3),Vector3(-3,0,18)]:
		b("ParkedCar",Vector3(2,1,4),pos+Vector3(0,.7,0),"a05248")
		b("CarCabin",Vector3(1.8,.7,2),pos+Vector3(0,1.5,-.2),"749caa")
		for x in [-1,1]:
			for z in [-1.3,1.3]:
				b("CarWheel",Vector3(.25,.65,.65),pos+Vector3(x,.4,z),"283137")
	for x in [-6,6]:
		for z in [-24,-9,9,24]:
			b("StreetLamp",Vector3(.15,5,.15),Vector3(x,2.5,z),"354b50")
			b("LampHead",Vector3(.8,.25,.8),Vector3(x,5,z),"ffe0a2",false)
	for i in range(9):
		b("CitySkyline",Vector3(6,12+i%4*4,6),Vector3(-34+i*8,5,-39),"788b98",false)
	world.label("SKYLINE DISTRICT",Vector3(0,5,-31),0,60)
func building(p: Vector3, floors: int, color: String) -> void:
	var height = floors*3.2
	b("Pavement",Vector3(13,.14,13),p+Vector3(0,.07,0),"b8bcb7")
	# Open ground-floor passages run through each block.
	for x in [-5.5,5.5]:
		b("BuildingSide",Vector3(.4,height,11),p+Vector3(x,height/2,0),color)
		for floor_id in range(floors):
			for z in [-3.5,0,3.5]:
				b("SideWindowTrim",Vector3(.18,1.9,2.3),p+Vector3(x*1.045,floor_id*3.2+1.5,z),"e4dfca",false)
				b("SideWindow",Vector3(.2,1.55,1.95),p+Vector3(x*1.065,floor_id*3.2+1.5,z),"4d798d",false)
	for z in [-5.5,5.5]:
		for x in [-3.75,3.75]:
			b("BuildingFront",Vector3(3.5,3,.4),p+Vector3(x,1.5,z),color)
		b("UpperFacade",Vector3(11,height-3,.4),p+Vector3(0,(height+3)/2,z),color)
		for floor_id in range(1,floors):
			for x in [-3.5,0,3.5]:
				b("WindowTrim",Vector3(2.3,1.9,.18),p+Vector3(x,floor_id*3.2+1.5,z*1.045),"e4dfca",false)
				b("CityWindow",Vector3(1.95,1.55,.2),p+Vector3(x,floor_id*3.2+1.5,z*1.065),"4d798d",false)
		b("ShopAwning",Vector3(10,.25,1.2),p+Vector3(0,2.8,z*1.08),"688d79")
	b("Roof",Vector3(11.7,.4,11.7),p+Vector3(0,height,0),"d4cbb5")
	b("RoofVent",Vector3(2.3,1,2),p+Vector3(2,height+.65,-2),"7c8a8a")
	b("ShopCounter",Vector3(2,1,1),p+Vector3(-3,.55,0),"9a7152")
	world.label("MARKET" if p.x<0 else "APARTMENTS",p+Vector3(0,3.5,5.8),0,28)
func valley_landmarks() -> void:
	# Terraced terrain outside the arena makes the village read as a voxel landscape.
	for side in [-1,1]:
		for i in range(8):
			var pos = Vector3(side*35,0,-28+i*8)
			for tier in range(3):
				b("DirtCliff",Vector3(8-tier*2,2,8),pos+Vector3(side*tier,1+tier*2,0),"805b3c",false)
				b("CliffGrass",Vector3(8-tier*2,.35,8),pos+Vector3(side*tier,2.1+tier*2,0),"588d35",false)
	# Obsidian gateway and luminous purple center.
	for x in [-2,2]:
		b("Obsidian",Vector3(1,6,1),Vector3(x,3,-25),"30283f")
	for y in [.5,5.5]:
		b("Obsidian",Vector3(5,1,1),Vector3(0,y,-25),"30283f")
	b("Portal",Vector3(3,4,.15),Vector3(0,3,-25),"9754cb",false)
	for i in range(15):
		b("PortalPixel",Vector3(.25,.5,.18),Vector3(-1.3+(i%5)*.6,1.4+(i/5 as int)*1.1,-24.9),"c27cf0",false)
	for p in [Vector3(-6,0,13),Vector3(6,0,-13)]:
		b("CraftingTable",Vector3(1.2,1.2,1.2),p+Vector3(0,.6,0),"946538")
		for i in range(4):
			b("CraftGrid",Vector3(.035,.02,1.1),p+Vector3(-.5+i*.33,1.21,0),"493728",false)
			b("CraftGrid",Vector3(1.1,.02,.035),p+Vector3(0,1.21,-.5+i*.33),"493728",false)
		b("Chest",Vector3(1.5,1,1),p+Vector3(2,.5,0),"b77c36")
		b("ChestBand",Vector3(1.52,.08,1.02),p+Vector3(2,.7,0),"453927",false)
		b("ChestLatch",Vector3(.18,.3,.07),p+Vector3(2,.6,.53),"ded8a7",false)
	for pos in [Vector3(-13,0,-17),Vector3(13,0,17),Vector3(13,0,-17),Vector3(-13,0,17)]:
		for x in [-2.8,2.8]:
			b("WindowCross",Vector3(1,.06,.1),pos+Vector3(x,2,3.76),"e3d8b4",false)
			b("WindowCross",Vector3(.06,1,.1),pos+Vector3(x,2,3.76),"e3d8b4",false)
		for y in [.4,.9]:
			b("CobbleBase",Vector3(8,.45,.12),pos+Vector3(0,y,-3.72),"92978b",false)

func city_landmarks() -> void:
	# Distinct rooflines, cornices, rooftop tanks, and a taller four-faced clock landmark.
	for p in [Vector3(-14,0,-17),Vector3(14,0,17),Vector3(-14,0,17),Vector3(14,0,-17)]:
		var h = 9.6 if p.x*p.z>0 else 12.8
		for y in [3.1,6.3,9.5,h+.5]:
			for side in [-1,1]:
				b("Cornice",Vector3(11.7,.2,.3),p+Vector3(0,y,side*5.65),"d0c4aa",false)
				b("Cornice",Vector3(.3,.2,11.7),p+Vector3(side*5.65,y,0),"d0c4aa",false)
		for side in [-1,1]:
			b("Parapet",Vector3(11.7,.7,.25),p+Vector3(0,h+.5,side*5.7),"a39a84")
			b("Parapet",Vector3(.25,.7,11.7),p+Vector3(side*5.7,h+.5,0),"a39a84")
		if p.x<0:
			for dx in [-1,1]:
				b("TankLeg",Vector3(.15,1.6,.15),p+Vector3(dx,h+1,0),"4f5557",false)
			b("WaterTank",Vector3(2.5,2.5,2.5),p+Vector3(0,h+2.5,0),"8a6852",false)
			for y in [h+1.5,h+3.4]:
				b("TankBand",Vector3(2.6,.15,2.6),p+Vector3(0,y,0),"464f52",false)
	var t = Vector3(22,0,2)
	for side in [-1,1]:
		b("ClockFace",Vector3(.08,2.5,2.5),t+Vector3(side*2.06,9.7,0),"ede7d2",false)
		b("ClockHand",Vector3(.1,.9,.13),t+Vector3(side*2.13,10,0),"333e45",false)
		b("ClockHand",Vector3(.1,.13,.7),t+Vector3(side*2.13,9.6,.28),"333e45",false)
		for tick in range(12):
			var a = tick*TAU/12
			b("ClockTick",Vector3(.12,.12,.1),t+Vector3(sin(a),9.7+cos(a),side*2.14),"424849",false)
			b("ClockTick",Vector3(.1,.12,.12),t+Vector3(side*2.14,9.7+cos(a),sin(a)),"424849",false)
	for i in range(5):
		b("TowerRoof",Vector3(4.8-i*.8,.5,4.8-i*.8),t+Vector3(0,12.5+i*.45,0),"47616a")
	b("TowerSpire",Vector3(.2,1.6,.2),t+Vector3(0,15,0),"37494e")
	# A yellow city bus supplies an unmistakable urban silhouette and street cover.
	var bus = Vector3(-22,0,1)
	b("CityBus",Vector3(2.8,2.5,7),bus+Vector3(0,1.6,0),"dcaa42")
	b("BusRoof",Vector3(2.9,.2,7.1),bus+Vector3(0,2.95,0),"d8d2b6")
	for side in [-1,1]:
		for z in [-2.4,-1.2,0,1.2,2.4]:
			b("BusWindow",Vector3(.06,.85,.95),bus+Vector3(side*1.43,2.15,z),"486f7f",false)
		for z in [-2.4,2.4]:
			b("BusWheel",Vector3(.3,.9,.9),bus+Vector3(side*1.4,.55,z),"283137")