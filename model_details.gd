extends RefCounted
static var materials: Dictionary = {}

static func part(parent: Node3D, size: Vector3, point: Vector3, color: String) -> void:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.position = point
	if not materials.has(color):
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(color)
		material.roughness = 0.85
		materials[color] = material
	mesh.material_override = materials[color]
	parent.add_child(mesh)

static func decorate(body: Node3D, kind: String, size: Vector3) -> void:
	if kind in ["CoverCrate","YardCover","SideCover"]:
		for side in [-1,1]:
			for x in [-0.35,0.35]:
				part(body,Vector3(0.075,size.y+0.025,0.035),Vector3(x*size.x,0,side*(size.z/2+0.02)),"554739")
			for row in range(4):
				part(body,Vector3(size.x,0.018,0.025),Vector3(0,-size.y/2+(row+1)*size.y/5,side*(size.z/2+0.025)),"795536")
	elif kind in ["Fence","BackFence"]:
		var along_x: bool = size.x > size.z
		var length: float = size.x if along_x else size.z
		for i in range(int(length/0.65)):
			var offset: float = -length/2+i*0.65
			part(body,Vector3(0.045,size.y,0.025) if along_x else Vector3(0.025,size.y,0.045),Vector3(offset,0,0.12) if along_x else Vector3(0.12,0,offset),"b59e79")
	elif kind in ["TreeTrunk","SignPost"]:
		for i in range(4):
			part(body,Vector3(0.055,size.y*0.17,0.025),Vector3(-size.x*0.25+(i%2)*size.x*0.4,-size.y*0.35+i*size.y*0.2,size.z/2+0.015),"674c38")
	elif kind in ["Leaves","LeafTop","Hedge"]:
		for i in range(5):
			part(body,Vector3(size.x*0.3,size.y*0.22,size.z*0.28),Vector3(sin(i*2.4)*size.x*0.4,size.y*0.42,cos(i*2.4)*size.z*0.4),"79b85a" if i%2 else "4b9c50")
	elif kind in ["Tire","CarWheel"]:
		for side in [-1,1]:
			part(body,Vector3(size.x*0.38,size.y*0.38,0.03),Vector3(0,0,side*(size.z/2+0.02)),"859099")
			for x in [-1,1]:
				for y in [-1,1]:
					part(body,Vector3(0.065,0.065,0.035),Vector3(x*size.x*0.12,y*size.y*0.12,side*(size.z/2+0.04)),"c0c5c6")
	elif kind in ["Sofa","BedCover"]:
		for x in [-0.3,0,0.3]:
			part(body,Vector3(0.022,0.025,size.z*0.92),Vector3(x*size.x,size.y/2+0.016,0),"e4d4b3")
	elif kind == "BedroomBed":
		for x in [-0.55,0.55]:
			part(body,Vector3(0.85,0.18,0.6),Vector3(x,size.y/2+0.12,-0.92),"f4ecdb")
	elif kind == "KitchenCounter":
		part(body,Vector3(size.x+0.06,0.08,size.z+0.05),Vector3(0,size.y/2+0.04,0),"f2efdf")
		for x in [-0.8,0,0.8]:
			part(body,Vector3(0.68,0.65,0.025),Vector3(x,0,size.z/2+0.02),"b4c2b7")
			part(body,Vector3(0.22,0.035,0.045),Vector3(x,0.22,size.z/2+0.05),"57616a")
	elif kind in ["Window","PixelGlass","Windshield"]:
		if size.z < 0.2:
			part(body,Vector3(0.055,size.y,0.025),Vector3(0,0,size.z/2+0.02),"c6d5cd")
			part(body,Vector3(size.x,0.045,0.025),Vector3(0,0,size.z/2+0.02),"c6d5cd")

static func character(parent: Node3D, enemy: bool) -> void:
	# Enemy origin is at capsule center; vendor origin is at ground level.
	var offset: float = 0.0 if enemy else 0.95
	var front: float = -1.0 if enemy else 1.0
	part(parent,Vector3(0.5,0.45,0.075),Vector3(0,0.2+offset,front*0.225),"454d45" if enemy else "45566b")
	for side in [-1,1]:
		part(parent,Vector3(0.17,0.19,0.075),Vector3(side*0.14,0.14+offset,front*0.29),"69725b")
		part(parent,Vector3(0.07,0.48,0.06),Vector3(side*0.23,0.22+offset,front*0.24),"303c38")
		part(parent,Vector3(0.055,0.05,0.025),Vector3(side*0.1,0.74+offset,front*0.22),"252d35")
	part(parent,Vector3(0.11,0.07,0.06),Vector3(0,0.66+offset,front*0.235),"b78865")
	part(parent,Vector3(0.47,0.12,0.47),Vector3(0,0.91+offset,0),"4a5352" if enemy else "344656")
	part(parent,Vector3(0.49,0.055,0.53),Vector3(0,0.84+offset,front*0.02),"343f3b")
	part(parent,Vector3(0.35,0.46,0.18),Vector3(0,0.18+offset,-front*0.28),"4c584b")
	part(parent,Vector3(0.65,0.07,0.42),Vector3(0,-0.08+offset,0),"303637")
