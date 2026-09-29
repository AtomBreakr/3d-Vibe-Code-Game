extends Node3D

var build_root: Node3D
var materials: Dictionary = {}

func _ready() -> void:
	_build_boundaries()
	var armory := CanvasLayer.new()
	armory.name = "Armory"
	armory.set_script(preload("res://armory.gd"))
	add_child(armory)
	var vendors := CanvasLayer.new()
	vendors.name = "Vendors"
	vendors.set_script(preload("res://vendors.gd"))
	add_child(vendors)
	var explosives := Node.new()
	explosives.name = "Explosives"
	explosives.set_script(preload("res://explosives.gd"))
	add_child(explosives)
	var vitals := CanvasLayer.new()
	vitals.name = "Vitals"
	vitals.set_script(preload("res://player_vitals.gd"))
	add_child(vitals)
	var scoreboard := CanvasLayer.new()
	scoreboard.name = "Scoreboard"
	scoreboard.set_script(preload("res://scoreboard.gd"))
	add_child(scoreboard)
	build_root = self
	_setup_controls()
	box("Terrain", Vector3(78, 1, 76), Vector3(0, -0.55, 0), "c7aa70")
	box("Grass", Vector3(62, 0.15, 66), Vector3(0, -0.05, 0), "72af48")
	box("Street", Vector3(60, 0.12, 12), Vector3(0, 0.04, 0), "42495b")
	for z in [-6.5, 6.5]:
		box("Sidewalk", Vector3(60, 0.22, 1), Vector3(0, 0.08, z), "d6d5bc")
	for x in range(-28, 30, 4):
		box("RoadPaint", Vector3(2, 0.02, 0.14), Vector3(x, 0.11, 0), "ffe1a0", false)
	for z in [-9, 9]:
		box("FrontPath", Vector3(2.5, 0.12, 5), Vector3(0, 0.08, z), "d6d5bc")
	house(Vector3(0, 0, -15), 0, "54c8cc", "278a9e", "01")
	house(Vector3(0, 0, 15), PI, "f3be54", "cc793c", "02")
	vehicle(Vector3(-6, 0, -1.8), false)
	vehicle(Vector3(6, 0, 2.0), true)
	_map_details()
	_expanded_yards()
	var enemies := Node.new()
	enemies.name = "Enemies"
	enemies.set_script(preload("res://enemy_manager.gd"))
	add_child(enemies)
	for side in [-1, 1]:
		for z in range(-32, 33, 2):
			box("FencePost", Vector3(0.22, 2, 0.22), Vector3(side * 30, 1, z), "eee1b6")
		box("Fence", Vector3(0.18, 1.5, 64), Vector3(side * 30, 0.85, 0), "d3bd88")
		for z in [-32, 32]:
			box("BackFence", Vector3(60, 1.8, 0.2), Vector3(0, 0.9, z), "d3bd88")
		for z in [-20, -9, 10, 21]:
			tree(Vector3(side * 19, 0, z))
		for z in [-22, 22]:
			box("GardenBed", Vector3(6, 0.35, 2), Vector3(side * 10, 0.17, z), "947058")
			for x in range(5):
				box("Hedge", Vector3(1, 1, 1.4), Vector3(side * 10 - 2 + x, 0.8, z), "438951")
		box("CoverCrate", Vector3(1.6, 1.5, 1.6), Vector3(side * 12, 0.75, side * 8), "b87948")
		box("CrateBand", Vector3(1.65, 0.16, 1.65), Vector3(side * 12, 1.1, side * 8), "e1b875", false)
		box("LampPole", Vector3(0.2, 5, 0.2), Vector3(side * 17, 2.5, -side * 6), "3a5060")
		box("Lamp", Vector3(1.3, 0.3, 0.6), Vector3(side * 17, 5, -side * 6), "ffedb0")
	# Pixel-like paving and grass patches break up otherwise flat surfaces.
	var rng := RandomNumberGenerator.new()
	rng.seed = 2025
	for i in range(150):
		var x := rng.randf_range(-29, 29)
		var z := rng.randf_range(-31, 31)
		if absf(z) > 7 and (absf(x) > 8 or absf(z) > 21):
			box("GrassPixel", Vector3(0.7, 0.02, 0.7), Vector3(x, 0.04, z), "8bc45a" if i % 2 else "639d42", false)
	for i in range(7):
		box("DistantMesa", Vector3(9, 3 + i % 3 * 2, 8), Vector3(-30 + i * 10, 1, -42), "b48b6a", false)
	$HUD/Instructions.hide()
	var rounds := CanvasLayer.new()
	rounds.name = "Rounds"
	rounds.set_script(preload("res://rounds.gd"))
	add_child(rounds)

func house(origin: Vector3, angle: float, wall: String, trim: String, number: String) -> void:
	var container := Node3D.new()
	container.name = "House" + number
	container.position = origin
	container.rotation.y = angle
	add_child(container)
	build_root = container
	box("Foundation", Vector3(14, 0.2, 10), Vector3(0, 0, 0), "eee1bf")
	# Front and rear doors remain open, linking the street and backyard.
	for z in [-5, 5]:
		for x in [-4.1, 4.1]:
			box("LowerWall", Vector3(5.8, 3.3, 0.3), Vector3(x, 1.7, z), wall)
		box("DoorLintel", Vector3(2.4, 0.7, 0.35), Vector3(0, 3, z), trim)
		for x in [-4.3, 4.3]:
			box("WindowFrame", Vector3(2.7, 1.6, 0.13), Vector3(x, 1.9, z + signf(z) * 0.18), "fff2d1", false)
			box("PixelGlass", Vector3(2.35, 1.28, 0.14), Vector3(x, 1.9, z + signf(z) * 0.26), "315a79", false)
			box("GlassHighlight", Vector3(0.4, 1.0, 0.05), Vector3(x - 0.7, 2, z + signf(z) * 0.35), "79d6df", false)
	for x in [-7, 7]:
		box("SideWall", Vector3(0.3, 3.4, 10), Vector3(x, 1.7, 0), wall)
	# Upper deck covers the left side; the right-side ramp leads through a floor opening.
	box("UpperFloor", Vector3(10, 0.25, 10), Vector3(-2, 3.5, 0), "f0dec0")
	box("UpperLanding", Vector3(4, 0.25, 2.5), Vector3(5, 3.5, -3.75), "f0dec0")
	for x in [-7, 7]:
		box("UpperSide", Vector3(0.3, 2.8, 10), Vector3(x, 5, 0), wall)
	box("UpperRear", Vector3(14, 2.8, 0.3), Vector3(0, 5, -5), wall)
	# Open observation windows across the front upstairs.
	box("UpperFrontSill", Vector3(14, 0.65, 0.3), Vector3(0, 3.95, 5), trim)
	for x in [-6.8, -2.3, 2.3, 6.8]:
		box("WindowPillar", Vector3(0.3, 2.2, 0.35), Vector3(x, 5.35, 5), "fff2d1")
	box("CantileverRoof",Vector3(16,0.32,11.8),Vector3(0,6.55,0),"f0eee1")
	# An invisible slope provides smooth walking over decorative voxel stairs.
	_stair_wedge(container)
	for i in range(16):
		var h: float = (i + 1) * 3.5 / 16
		box("Stair", Vector3(2.7, h, 0.49), Vector3(5, h / 2, 4.5 - i * 0.49), "d7c6a5", false)
	box("Sofa", Vector3(3, 0.65, 1.1), Vector3(-4, 0.5, -2), trim)
	box("SofaBack", Vector3(3, 1.1, 0.3), Vector3(-4, 0.85, -2.5), trim)
	box("Table", Vector3(2, 0.7, 1.2), Vector3(-3.5, 0.35, 0.2), "a57450")
	box("Rug", Vector3(4, 0.03, 4), Vector3(-3, 0.13, 0), "c78870", false)
	_house_details(wall,trim)
	_house_trim(trim)
	label(number, Vector3(0, 3.05, 5.2), 0, 36)
	build_root = self

func vehicle(origin: Vector3, truck: bool) -> void:
	var container := Node3D.new()
	container.position = origin
	container.name = "MovingTruck" if truck else "SchoolBus"
	add_child(container)
	build_root = container
	var paint: String = "e5e6d8" if truck else "f6be42"
	box("Chassis", Vector3(8.6, 0.55, 3), Vector3(0, 0.85, 0), "303744")
	box("Body", Vector3(8.2, 2.6, 2.9), Vector3(0, 2.2, 0), paint)
	box("Roof", Vector3(8.4, 0.25, 3.1), Vector3(0, 3.6, 0), paint)
	for side in [-1, 1]:
		box("Stripe", Vector3(8.3, 0.28, 0.06), Vector3(0, 1.75, side * 1.48), "da7150" if truck else "424357", false)
		for x in [-2.7, 2.7]:
			box("Tire", Vector3(1.35, 1.35, 0.45), Vector3(x, 0.7, side * 1.45), "28313e")
			box("Hub", Vector3(0.65, 0.65, 0.08), Vector3(x, 0.7, side * 1.71), "97abba", false)
		for i in range(5 if not truck else 1):
			box("Window", Vector3(1.1, 1.0, 0.06), Vector3(-3 + i * 1.45, 2.85, side * 1.48), "366482", false)
	box("Windshield", Vector3(0.06, 1.1, 2.5), Vector3(-4.13, 2.8, 0), "366482", false)
	for z in [-1, 1]:
		box("Headlight", Vector3(0.08, 0.4, 0.5), Vector3(-4.15, 1.5, z), "fff0bb", false)
	_vehicle_trim()
	if truck:
		label("BOX / CO.", Vector3(0.6, 2.7, 1.52), 0, 32)
	build_root = self

func tree(origin: Vector3) -> void:
	box("TreeTrunk", Vector3(0.65, 3, 0.65), origin + Vector3(0, 1.5, 0), "8a6246")
	box("Leaves", Vector3(3.5, 2.4, 3.5), origin + Vector3(0, 3.3, 0), "3e9256")
	box("LeafTop", Vector3(2.3, 1.2, 2.3), origin + Vector3(0.3, 4.8, 0), "69b657")

func label(words: String, location: Vector3, angle: float, size: int) -> void:
	var text := Label3D.new()
	text.text = words
	text.position = location
	text.rotation.y = angle
	text.font_size = size
	text.pixel_size = 0.009
	text.outline_size = 3
	text.modulate = Color("fff1cf")
	build_root.add_child(text)

func _setup_controls() -> void:
	get_node("/root/GameSettings").apply()
	get_node("/root/GameSettings").call_deferred("apply_world")

func box(box_name: String, size: Vector3, location: Vector3, hex: String, solid: bool = true) -> Node3D:
	var body: Node3D = StaticBody3D.new() if solid else Node3D.new()
	body.name = box_name
	body.position = location
	var mesh := MeshInstance3D.new()
	var shape_mesh := BoxMesh.new()
	shape_mesh.size = size
	mesh.mesh = shape_mesh
	if not materials.has(hex):
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(hex)
		material.roughness = 1.0
		materials[hex] = material
	mesh.material_override = materials[hex]
	body.add_child(mesh)
	if solid:
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		body.add_child(collision)
	build_root.add_child(body)
	preload("res://model_details.gd").decorate(body,box_name,size)
	return body


func _build_boundaries() -> void:
	for side in [-1, 1]:
		_boundary(Vector3(1, 80, 66), Vector3(side * 30.4, 35, 0))
		_boundary(Vector3(62, 80, 1), Vector3(0, 35, side * 32.4))

func _boundary(size: Vector3, location: Vector3) -> void:
	var wall := StaticBody3D.new()
	wall.name = "ArenaBoundary"
	wall.position = location
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	wall.add_child(collision)
	add_child(wall)

func _stair_wedge(parent: Node3D) -> void:
	# Continuous slope meets the upper landing exactly, with no vertical lip.
	var body := StaticBody3D.new()
	body.name = "StairRamp"
	var collision := CollisionShape3D.new()
	var shape := ConvexPolygonShape3D.new()
	var points := PackedVector3Array()
	for x in [3.65,6.35]:
		points.append(Vector3(x,0.025,4.7))
		points.append(Vector3(x,0.10,4.7))
		points.append(Vector3(x,0.025,-2.5))
		points.append(Vector3(x,3.625,-2.5))
	shape.points = points
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)

func _house_details(wall: String, trim: String) -> void:
	box("WhiteBelt",Vector3(14.4,0.28,0.4),Vector3(0,3.4,5.18),"ecebdd",false)
	box("EntryCanopy",Vector3(5.5,0.18,1.5),Vector3(0,3.2,5.7),"e9e7dc")
	for x in [-6.7,-5.9,-5.1,5.1,5.9,6.7]:
		box("FacadeFin",Vector3(0.15,2.35,0.75),Vector3(x,5.1,5.35),"eee9d5",false)
	for x in [-2.0,2.0]:
		box("PorchPost",Vector3(0.16,3.1,0.16),Vector3(x,1.55,6.25),trim)
	box("Driveway",Vector3(6,0.14,14),Vector3(-10,0.04,1.7),"bfc3bb")
	box("GarageOuter",Vector3(0.25,3.3,8),Vector3(-13,1.65,0),wall)
	box("GarageRoof",Vector3(6.6,0.25,8.8),Vector3(-10,3.4,0),"e7e7dc")
	box("GarageHeader",Vector3(6,0.55,0.25),Vector3(-10,3.05,4),trim)
	box("GarageRearLeft",Vector3(2,3.2,0.2),Vector3(-12,1.6,-4),wall)
	box("GarageRearRight",Vector3(1.8,3.2,0.2),Vector3(-7.9,1.6,-4),wall)
	box("Workbench",Vector3(1,0.9,2.6),Vector3(-12.2,0.45,-0.8),"967249")
	box("Patio",Vector3(10,0.15,2.7),Vector3(0,0.025,-6.5),"c2aa83")
	box("PatioTable",Vector3(1.8,0.75,1.1),Vector3(-3,0.375,-6.3),"e7e0c9")
	for x in [-4.5,-1.5]:
		box("PatioChair",Vector3(0.6,0.55,0.6),Vector3(x,0.28,-6.3),trim)
	box("GardenShed",Vector3(3.2,2.4,2.2),Vector3(9.2,1.2,-7.2),trim)
	box("ShedRoof",Vector3(3.7,0.25,2.6),Vector3(9.2,2.5,-7.2),"e8e1ca")
	box("ShedDoor",Vector3(1.1,1.95,0.03),Vector3(9.2,1,-6.07),"ded7b8",false)
	box("BedroomBed",Vector3(2.4,0.55,2.8),Vector3(-4.4,3.95,-2.5),"e1ddd0")
	box("BedCover",Vector3(2.4,0.15,1.8),Vector3(-4.4,4.3,-2.1),trim,false)
	box("KitchenCounter",Vector3(2.5,0.95,0.7),Vector3(-4.3,0.55,-4.3),"d7dedb")
	_mannequin(Vector3(2.3,0,6.1),"bd7663")
	_mannequin(Vector3(-2,0,-7.1),"769cab")

func _mannequin(origin: Vector3, color: String) -> void:
	box("MannequinTorso",Vector3(0.45,0.65,0.27),origin+Vector3(0,1.15,0),color)
	box("MannequinHead",Vector3(0.28,0.32,0.28),origin+Vector3(0,1.66,0),"dfcdb0")
	for side in [-1,1]:
		box("MannequinLeg",Vector3(0.16,0.8,0.18),origin+Vector3(side*0.13,0.42,0),"485868")
		box("MannequinArm",Vector3(0.14,0.65,0.16),origin+Vector3(side*0.33,1.06,0),color)

func _map_details() -> void:
	for side in [-1,1]:
		box("MailboxPost",Vector3(0.13,1.0,0.13),Vector3(side*8,0.5,side*7.8),"b8b4a3")
		box("Mailbox",Vector3(0.7,0.4,0.35),Vector3(side*8,1.1,side*7.8),"b2524a")
		box("CarBody",Vector3(4.0,0.65,1.8),Vector3(side*18,0.65,side*2),"74b9b1" if side==1 else "d69b70")
		box("CarCabin",Vector3(2.0,0.7,1.6),Vector3(side*18,1.3,side*2),"52717d")
		for dx in [-1.25,1.25]:
			for dz in [-0.85,0.85]:
				box("CarWheel",Vector3(0.7,0.7,0.22),Vector3(side*18+dx,0.4,side*2+dz),"29333c")
	box("TestSiteTower",Vector3(1.5,14,1.5),Vector3(36,7,-39),"9b9d93",false)
	box("WaterTank",Vector3(6,4,6),Vector3(36,15,-39),"c5cec5",false)


func _expanded_yards() -> void:
	for side in [-1,1]:
		box("SideLane",Vector3(3,0.10,48),Vector3(side*25,0.01,0),"bfb7a0")
		for z in [-27,27]:
			box("RearPath",Vector3(48,0.10,2),Vector3(0,0.01,z),"bfb7a0")
			box("YardCover",Vector3(2.5,1.3,1.5),Vector3(side*19,0.65,z),"a8784d")
			tree(Vector3(side*27,0,z))
		for z in [-14,14]:
			box("SideCover",Vector3(1.7,1.4,2.4),Vector3(side*22,0.7,z),"a8784d")
func _house_trim(trim: String) -> void:
	for side in [-1,1]:
		box("Gutter",Vector3(0.15,0.15,11.5),Vector3(side*7.65,6.5,0),"aab8b6",false)
		box("Downspout",Vector3(0.12,6.1,0.12),Vector3(side*7.2,3.1,-4.7),"d5ddd4",false)
		for y in [0.55,1.05,1.55,2.05,2.55,3.05]:
			box("SidingSeam",Vector3(0.025,0.025,9.8),Vector3(side*7.16,y,0),trim,false)
		box("PorchLight",Vector3(0.22,0.4,0.2),Vector3(side*1.6,2.45,5.3),"fff0c2",false)
	for x in [-4.3,4.3]:
		box("FlowerBox",Vector3(2.3,0.25,0.4),Vector3(x,0.95,5.4),"865f43",false)
		for i in range(5):
			box("FlowerLeaf",Vector3(0.25,0.22,0.25),Vector3(x-0.8+i*0.4,1.16,5.4),"4d8751",false)
			box("Flower",Vector3(0.13,0.12,0.13),Vector3(x-0.8+i*0.4,1.32,5.4),"e99786" if i%2 else "f0cd69",false)
	box("RoofVent",Vector3(0.8,0.5,0.65),Vector3(-3,6.95,-2),"9ca6a6",false)
	for z in [-2.2,-2,-1.8]:
		box("VentSlat",Vector3(0.82,0.06,0.07),Vector3(-3,7.05,z),"535f64",false)
	box("WallPicture",Vector3(1.7,1.1,0.05),Vector3(-3.7,2.1,-4.78),"89664e",false)
	box("PictureInset",Vector3(1.45,0.85,0.06),Vector3(-3.7,2.1,-4.74),"76a4ad",false)
	box("TableBook",Vector3(0.55,0.08,0.38),Vector3(-3.8,0.75,0.2),"527e8c",false)
	box("TableCup",Vector3(0.16,0.22,0.16),Vector3(-3,0.82,0.2),"eae1c9",false)

func _vehicle_trim() -> void:
	for end in [-1,1]:
		box("Bumper",Vector3(0.16,0.22,3.05),Vector3(end*4.23,0.95,0),"8c9b9e",false)
		box("LicensePlate",Vector3(0.025,0.22,0.5),Vector3(end*4.32,1.2,0),"e6ddbf",false)
	for z in [-1,1]:
		box("MirrorArm",Vector3(0.22,0.1,0.45),Vector3(-3.8,2.55,z*1.66),"48535b",false)
		box("Mirror",Vector3(0.14,0.34,0.25),Vector3(-3.8,2.65,z*1.9),"b8cbd0",false)
		box("RearLamp",Vector3(0.08,0.38,0.28),Vector3(4.15,1.55,z),"d45e4c",false)
		box("DoorHandle",Vector3(0.36,0.055,0.08),Vector3(-2.8,2.12,z*1.53),"dce0ce",false)
	for z in range(7):
		box("Grille",Vector3(0.035,0.45,0.06),Vector3(-4.2,1.6,-0.6+z*0.2),"414c56",false)