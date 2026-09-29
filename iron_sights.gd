extends RefCounted

static var heights: Dictionary = {}
static func height(category: int, index: int) -> float:
	var key := Vector2i(category,index)
	if heights.has(key):
		return heights[key]
	var value := 0.12
	if category == 1:
		value = 0.112 if index == 0 else 0.098
	elif category == 0 and index in [0,7]:
		value = 0.105
	# Keep the sight axis above every receiver/slide piece retained during ADS.
	for part in preload("res://weapon_catalog.gd").geometry(category,index):
		var size: Vector3 = part[0]
		var point: Vector3 = part[1]
		if point.y < 0.06 and absf(point.x) <= size.x/2:
			value = maxf(value,point.y+size.y/2+0.018)
	heights[key] = value
	return value
static func build(weapon: Node3D, category: int, index: int) -> void:
	var root := Node3D.new()
	root.name = "AlignedSights"
	weapon.add_child(root)
	var h := height(category,index)
	var catalog = preload("res://weapon_catalog.gd")
	var profile: Array = catalog.PROFILES[category][index]
	var front: float = catalog.muzzle_position(category,index).z + 0.08
	var rear: float = minf(0.19,float(profile[3])*0.35)
	var detail = preload("res://model_details.gd")
	var notch: bool = category == 1 or (category == 0 and index in [0,7]) or (category == 2 and index in [0,5,7,8,9])
	# Sight bases physically join the receiver and barrel; all parts share the gun transform.
	detail.part(root,Vector3(0.075,0.016,0.05),Vector3(0,0.058,rear),"343e43")
	if notch:
		for side in [-1,1]:
			detail.part(root,Vector3(0.022,h-0.055,0.021),Vector3(side*0.023,(h+0.055)/2,rear),"273136")
			if category == 1 and index not in [1,6,7]:
				detail.part(root,Vector3(0.005,0.005,0.003),Vector3(side*0.023,h-0.006,rear+0.012),"eee9c9")
	else:
		var ring := MeshInstance3D.new()
		var mesh := TorusMesh.new()
		mesh.inner_radius = 0.023
		mesh.outer_radius = 0.029
		mesh.rings = 16
		mesh.ring_segments = 6
		ring.mesh = mesh
		ring.position = Vector3(0,h,rear)
		ring.rotation.x = PI/2
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color("273136")
		ring.material_override = mat
		root.add_child(ring)
		detail.part(root,Vector3(0.018,h-0.075,0.023),Vector3(0,(h+0.025)/2,rear),"343e43")
	# Front post terminates exactly on the common optical axis.
	detail.part(root,Vector3(0.007,h-0.025,0.016),Vector3(0,(h+0.025)/2,front),"273136")
	detail.part(root,Vector3(0.045,0.017,0.04),Vector3(0,0.035,front),"343e43")
	if category != 1:
		for side in [-1,1]:
			detail.part(root,Vector3(0.008,h*0.5,0.023),Vector3(side*0.026,h*0.52,front),"343e43")
	elif index not in [1,6,7]:
		detail.part(root,Vector3(0.004,0.004,0.003),Vector3(0,h-0.005,front+0.009),"eee9c9")
