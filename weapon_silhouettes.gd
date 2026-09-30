extends RefCounted
# Silhouette treatment uses faceted volumes instead of assembling every surface from cubes.
static func refine(parts: Array, category: int, index: int, profile: Array) -> Array:
	var result: Array = []
	var length: float = profile[3]
	var metal := Color(profile[1])
	var furniture := Color(profile[2])
	for i in range(parts.size()):
		var source: Array = parts[i]
		var size: Vector3 = source[0]
		var point: Vector3 = source[1]
		var color: Color = source[2]
		var kind := "box"
		var rotation := Vector3.ZERO
		if category in [0,2,4] and profile[5] == "curve" and is_equal_approx(size.y,0.062):
			rotation.x = clampf((-point.y-0.06)*2.0,0.08,0.45)
			size.y *= 1.12
		if category == 0 and profile[6] == "bullpup":
			if i == 2:
				point.z = -0.075
			if size.y >= 0.15 and point.z > length/2 and point.y > -0.07:
				size = Vector3(0.10,0.16,0.22)
				point = Vector3(0,-0.025,length/2+0.035)
		if i == 0 and category != 5:
			kind = "bevel"
			if category == 1:
				size.x = 0.095 if index == 0 else 0.073
				size.y = 0.09 if index == 0 else 0.074
				if index == 3:
					# Open-slide profile: a rear bridge and two low side rails expose the barrel.
					result.append([Vector3(size.x,size.y,length*0.33),Vector3(0,0,length*0.335),color,"bevel",rotation])
					for side in [-1,1]:
						result.append([Vector3(0.016,0.041,length*0.67),Vector3(side*0.029,-0.018,-length*0.165),color,"bevel",rotation])
					result.append([Vector3(0.033,0.033,length*0.75),Vector3(0,0.013,-length*0.14),metal.lightened(0.12),"tube",rotation])
					continue
			else:
				size.x *= 0.85
				size.y *= 0.80
		# Round components retain visible facets, rather than perfectly smooth cylinders.
		if size.z > maxf(size.x,size.y)*2.2 and absf(size.x-size.y) < 0.025 and size.x < 0.13:
			kind = "tube"
		if category == 3 and size.z > 0.25 and point.y > -0.01:
			kind = "tube"
		if category == 3 and profile[7] == "warhead" and point.z < -length/2-0.20:
			kind = "cone"
		if category != 3 and size.y > 0.12 and size.z > 0.12 and point.z > length*0.4:
			kind = "stock"
		if size.y > 0.10 and size.x > 0.05 and point.y < -0.05:
			kind = "bevel"
			if point.z > 0.03 and size.z < 0.12:
				rotation.x = -0.20 if category != 1 else (-0.38 if index == 7 else -0.22)
		if category == 1 and index == 0 and point.y >= 0.06 and size.x >= 0.10:
			kind = "bevel"
		if category in [0,2,4] and point.z < -length*0.15 and size.x > 0.08 and size.y > 0.065 and size.z > 0.1:
			kind = "bevel"
		if category == 5:
			kind = "bevel"
			if profile[7] == "bat":
				kind = "tube"
			if profile[7] in ["knife","blade","kukri"] and point.z < -0.1:
				kind = "stock"
		result.append([size,point,color,kind,rotation])
	# Distinctive larger forms matter more than extra surface pixels.
	if category == 0:
		if index in [0,7]:
			result.append([Vector3(0.09,0.075,0.19),Vector3(0,-0.015,-length*0.53),furniture,"bevel",Vector3.ZERO])
		elif index == 4:
			result.append([Vector3(0.045,0.15,0.055),Vector3(0,-0.10,-0.19),furniture,"bevel",Vector3(-0.18,0,0)])
			result.append([Vector3(0.035,0.018,0.18),Vector3(0,-0.17,0.025),furniture,"bevel",Vector3.ZERO])
		elif index in [1,2]:
			result.append([Vector3(0.045,0.045,0.16),Vector3(0,-0.025,length/2+0.03),metal,"tube",Vector3.ZERO])
		elif index == 3:
			result.append([Vector3(0.052,0.115,0.045),Vector3(0.01,-0.018,length/2+0.025),metal.darkened(0.25),"bevel",Vector3.ZERO])
	if category == 4:
		result.append([Vector3(0.07,0.018,0.018),Vector3(0.06,0.025,0.13),metal,"bevel",Vector3(0,0,-0.35)])
		result.append([Vector3(0.035,0.035,0.035),Vector3(0.095,0.01,0.13),metal.darkened(0.3),"bevel",Vector3.ZERO])
	return result
