extends RefCounted
# Stylized visual profiles only: name, finish, furniture, body length,
# barrel length, magazine silhouette, stock silhouette, signature feature.
const PROFILES := [
[
["AK-47","414744","a1683c",0.36,0.25,"curve","solid","gas"],
["M16A2","424d52","303839",0.38,0.34,"box","solid","carry"],
["M4A1","41494d","363b3c",0.32,0.23,"box","telescopic","rail"],
["FN SCAR-L","a39470","c0ad80",0.35,0.24,"box","fold","rail"],
["Steyr AUG","454d48","929b71",0.38,0.26,"rear","bullpup","scope"],
["FAMAS F1","424a49","4d5850",0.34,0.23,"rear","bullpup","carry"],
["HK G36","42494e","4a5154",0.36,0.27,"box","skeleton","carry"],
["AK-74","43494b","ad7042",0.37,0.28,"curve","solid","brake"],
["SIG SG 550","535e5b","66795c",0.39,0.30,"box","skeleton","bipod"],
["IWI Tavor X95","494d46","6c7156",0.32,0.19,"rear","bullpup","rail"]
],
[
["Desert Eagle","b9c1c5","42464b",0.29,0.07,"none","none","heavy"],
["Colt M1911","7f898e","986342",0.24,0.035,"none","none","classic"],
["Glock 17","50595c","343d3f",0.23,0.025,"none","none","square"],
["Beretta 92FS","78848b","363b3c",0.26,0.045,"none","none","open_slide"],
["SIG P226","556169","414548",0.245,0.03,"none","none","hammer"],
["HK USP","505759","3d4441",0.255,0.025,"none","none","rail"],
["Walther P38","7d8687","744f34",0.20,0.11,"none","none","classic"],
["Luger P08","636f73","976342",0.16,0.16,"none","none","toggle"],
["FN Five-seveN","565e63","6c7166",0.265,0.035,"none","none","square"],
["CZ 75","788388","564b3d",0.235,0.04,"none","none","hammer"]
],
[
["M2 Browning","525a58","464c4a",0.52,0.65,"belt","spade","heavy"],
["M249 SAW","555e57","5d694d",0.39,0.34,"belt","skeleton","bipod"],
["M240B","505955","695b47",0.46,0.42,"belt","solid","bipod"],
["M60","515b54","53604b",0.43,0.39,"belt","solid","gas"],
["PKM","515953","a07143",0.42,0.43,"belt","skeleton","bipod"],
["RPK","515b55","a97641",0.39,0.39,"curve","solid","bipod"],
["MG42","626b67","916b48",0.47,0.42,"belt","solid","shroud"],
["Bren Mk II","5b6560","a06d42",0.40,0.40,"top","solid","bipod"],
["DP-27","596359","9a703f",0.42,0.42,"pan","solid","bipod"],
["Lewis Gun","5d6961","8d633f",0.39,0.50,"pan","solid","shroud"]
],
[
["RPG-7","67744e","a37042",0.65,0.23,"none","none","warhead"],
["M72 LAW","73815d","535c4c",0.64,0.03,"none","none","compact"],
["AT4","7d875a","343d36",0.84,0.02,"none","none","bands"],
["RPG-18","78835c","525d4f",0.68,0.035,"none","none","compact"],
["RPG-22","758658","465142",0.73,0.025,"none","none","bands"],
["RPG-26","65784f","404a3c",0.78,0.025,"none","none","compact"],
["RPG-29","637548","535f41",0.98,0.10,"none","none","scope"],
["Mk 153 SMAW","7c8760","434d40",0.87,0.08,"none","none","spotter"],
["M1 Bazooka","6e7756","88673f",0.95,0.02,"none","none","open_tube"],
["M20 Super Bazooka","65714f","8d7147",1.05,0.03,"none","none","shield"]
],
[
["AWM","53615a","91a578",0.42,0.49,"box","thumbhole","scope"],
["Barrett M82A1","666c64","797961",0.51,0.60,"box","skeleton","brake"],
["Remington M24","536059","596549",0.39,0.48,"none","solid","scope"],
["M40A5","535d54","77916c",0.41,0.45,"box","solid","scope"],
["Dragunov SVD","5e655d","a87946",0.42,0.49,"curve","thumbhole","scope"],
["HK PSG1","515b58","624d39",0.43,0.47,"box","thumbhole","scope"],
["CheyTac M200","676c63","b5a17b",0.44,0.63,"box","telescopic","bipod"],
["Sako TRG 42","535e57","719275",0.42,0.53,"box","fold","scope"],
["Steyr SSG 69","536259","728063",0.38,0.46,"none","solid","scope"],
["Mosin-Nagant PU","596259","a47543",0.45,0.54,"none","solid","wood"]
],
[
["Combat Knife","bac5cc","474b43",0.30,0.0,"none","none","knife"],
["Bayonet","9caeb7","795c43",0.38,0.0,"none","none","knife"],
["Bowie Knife","b1bdc3","92633f",0.34,0.0,"none","none","knife"],
["Tanto","a5b8c2","313c43",0.28,0.0,"none","none","knife"],
["Kukri","a2afb4","755035",0.40,0.0,"none","none","kukri"],
["Machete","a7b9be","595340",0.52,0.0,"none","none","blade"],
["Tomahawk","8398a1","916440",0.37,0.0,"none","none","axe"],
["Hatchet","8d9da2","9c754b",0.32,0.0,"none","none","axe"],
["Baseball Bat","b39770","88693c",0.62,0.0,"none","none","bat"],
["Crowbar","76848d","343d43",0.55,0.0,"none","none","crowbar"]
]
]

static func geometry(category: int, index: int) -> Array:
	if category == 5:
		return melee_geometry(index)
	var p: Array = PROFILES[category][index]
	var metal := Color(p[1])
	var furniture := Color(p[2])
	var dark := Color("30383b")
	var length: float = p[3]
	var barrel: float = p[4]
	var parts: Array = []
	add(parts, Vector3(0.105, 0.115, length), Vector3.ZERO, metal)
	add(parts, Vector3(0.04, 0.04, barrel), Vector3(0, 0.025, -(length + barrel) / 2), dark)
	add(parts, Vector3(0.07, 0.17, 0.09), Vector3(0, -0.12, length * 0.3), furniture)
	if category == 1:
		add(parts, Vector3(0.08, 0.065, length * 0.8), Vector3(0, -0.07, -0.02), metal.darkened(0.2))
		add(parts, Vector3(0.018, 0.035, 0.025), Vector3(0, 0.073, -length * 0.4), dark)
		add(parts, Vector3(0.02, 0.025, 0.025), Vector3(0, 0.073, length * 0.4), dark)
		if p[7] == "heavy":
			add(parts, Vector3(0.12, 0.06, 0.21), Vector3(0, 0.06, -0.04), metal)
		elif p[7] == "toggle":
			add(parts, Vector3(0.125, 0.05, 0.04), Vector3(0, 0.075, 0.04), dark)
		elif p[7] == "open_slide":
			add(parts, Vector3(0.045, 0.025, 0.14), Vector3(0, 0.065, -0.07), dark)
		elif p[7] in ["classic", "hammer"]:
			add(parts, Vector3(0.025, 0.065, 0.04), Vector3(0, 0.05, length * 0.5), dark)
		else:
			add(parts, Vector3(0.095, 0.025, 0.11), Vector3(0, -0.085, -0.08), dark)
	elif category == 3:
		var width: float = 0.12 if p[7] in ["open_tube", "compact"] else 0.20
		add(parts, Vector3(width, width, length), Vector3(0, 0.045, 0), furniture)
		for end in [-1, 1]:
			add(parts, Vector3(width + 0.04, width + 0.04, 0.055), Vector3(0, 0.045, end * length / 2), dark)
		add(parts, Vector3(width * 0.75, width * 0.75, 0.012), Vector3(0, 0.045, -length / 2 - 0.034), Color("151d22"))
		add(parts, Vector3(0.04, 0.16, 0.06), Vector3(0.09, 0.17, -0.1), dark)
		if p[7] == "warhead":
			add(parts, Vector3(0.18, 0.18, 0.19), Vector3(0, 0.03, -length / 2 - 0.14), furniture)
			add(parts, Vector3(0.10, 0.10, 0.13), Vector3(0, 0.03, -length / 2 - 0.29), furniture)
		if p[7] == "spotter":
			add(parts, Vector3(0.055, 0.07, 0.40), Vector3(-0.14, -0.06, -0.14), dark)
		if p[7] == "shield":
			add(parts, Vector3(0.3, 0.27, 0.025), Vector3(0, 0.06, -0.12), furniture)
	else:
		add(parts, Vector3(0.11, 0.11, length * 0.48), Vector3(0, -0.012, -length * 0.40), furniture)
		var stock: String = p[6]
		if stock == "spade":
			for side in [-1, 1]:
				add(parts, Vector3(0.05, 0.19, 0.06), Vector3(side * 0.14, -0.02, length / 2 + 0.05), furniture)
		elif stock in ["skeleton", "thumbhole"]:
			add(parts, Vector3(0.07, 0.035, 0.25), Vector3(0, 0.02, length / 2 + 0.1), furniture)
			add(parts, Vector3(0.07, 0.035, 0.25), Vector3(0, -0.1, length / 2 + 0.1), furniture)
			add(parts, Vector3(0.08, 0.16, 0.04), Vector3(0, -0.04, length / 2 + 0.22), furniture)
		else:
			add(parts, Vector3(0.10, 0.15, 0.22 if stock != "bullpup" else 0.13), Vector3(0, -0.025, length / 2 + 0.08), furniture)
			if stock == "telescopic":
				add(parts, Vector3(0.045, 0.045, 0.15), Vector3(0, 0.025, length / 2), dark)
		var mag: String = p[5]
		if mag == "curve":
			for segment in range(4):
				add(parts, Vector3(0.065, 0.062, 0.095), Vector3(0, -0.09 - segment * 0.047, -0.03 - segment * segment * 0.008), dark)
		elif mag in ["box", "rear"]:
			add(parts, Vector3(0.065, 0.22, 0.095), Vector3(0, -0.14, 0.17 if mag == "rear" else -0.04), metal)
		elif mag == "belt":
			add(parts, Vector3(0.20, 0.18, 0.18), Vector3(-0.12, -0.1, 0), furniture)
			for link in range(5):
				add(parts, Vector3(0.025, 0.026, 0.07), Vector3(-0.08 - link * 0.027, 0.025, 0), Color("bca16b"))
		elif mag == "top":
			add(parts, Vector3(0.065, 0.23, 0.12), Vector3(0, 0.15, -0.04), dark)
		elif mag == "pan":
			add(parts, Vector3(0.30, 0.065, 0.30), Vector3(0, 0.1, -0.04), dark)
		if p[7] == "carry":
			for z in [-0.08, 0.12]:
				add(parts, Vector3(0.035, 0.10, 0.025), Vector3(0, 0.1, z), dark)
			add(parts, Vector3(0.04, 0.035, 0.25), Vector3(0, 0.15, 0.02), dark)
		if p[7] in ["gas", "brake"]:
			add(parts, Vector3(0.04, 0.04, 0.22), Vector3(0, 0.075, -length * 0.55), dark)
		if p[7] == "shroud":
			add(parts, Vector3(0.10, 0.10, barrel * 0.85), Vector3(0, 0.025, -length / 2 - barrel * 0.4), metal)
			for slot in range(6):
				add(parts, Vector3(0.105, 0.035, 0.025), Vector3(0, 0.035, -length / 2 - slot * 0.055), dark)
		if p[7] == "rail":
			for slot in range(7):
				add(parts, Vector3(0.07, 0.02, 0.025), Vector3(0, 0.07, -0.15 + slot * 0.045), dark)
	if category == 4 or p[7] == "scope":
		add(parts, Vector3(0.035, 0.10, 0.1), Vector3(0, 0.10, 0), dark)
		add(parts, Vector3(0.08, 0.08, 0.27), Vector3(0, 0.17, 0), dark)
		for end in [-1, 1]:
			add(parts, Vector3(0.105, 0.105, 0.04), Vector3(0, 0.17, end * 0.14), dark)
		add(parts, Vector3(0.075, 0.075, 0.01), Vector3(0, 0.17, 0.165), Color("69b6c4"))
	if p[7] == "bipod" or (category == 4 and index in [1, 6, 7]):
		for side in [-1, 1]:
			add(parts, Vector3(0.025, 0.19, 0.025), Vector3(side * 0.075, -0.1, -length / 2 - barrel * 0.4), dark)
	if p[7] == "brake":
		add(parts, Vector3(0.12, 0.07, 0.09), Vector3(0, 0.025, -length / 2 - barrel), dark)
	_details(parts, category, index)
	_finish_details(parts,category,index)
	return parts

static func add(parts: Array, size: Vector3, position: Vector3, color: Color) -> void:
	parts.append([size, position, color])

static func _details(parts: Array, category: int, index: int) -> void:
	var p: Array = PROFILES[category][index]
	var metal := Color(p[1])
	var furniture := Color(p[2])
	var edge := metal.lightened(0.24)
	var dark := Color("232b30")
	var length: float = p[3]
	var barrel: float = p[4]
	# Layered receiver, side panels, pins and visible grip texture.
	add(parts, Vector3(0.086, 0.018, length * 0.82), Vector3(0, 0.064, 0), edge)
	for side in [-1, 1]:
		add(parts, Vector3(0.008, 0.055, length * 0.48), Vector3(side * 0.056, 0, 0.025), metal.darkened(0.16))
		for pin in [-0.07, 0.06]:
			add(parts, Vector3(0.012, 0.013, 0.013), Vector3(side * 0.062, -0.02, pin), edge)
		for groove in range(5):
			add(parts, Vector3(0.006, 0.008, 0.07), Vector3(side * 0.038, -0.065 - groove * 0.025, length * 0.3), furniture.darkened(0.35))
	# Open trigger guard: three thin pieces preserve a visible gap.
	var guard_z: float = length * 0.3 - 0.07
	add(parts, Vector3(0.045, 0.014, 0.11), Vector3(0, -0.15, guard_z - 0.035), dark)
	add(parts, Vector3(0.045, 0.09, 0.014), Vector3(0, -0.105, guard_z - 0.085), dark)
	add(parts, Vector3(0.018, 0.05, 0.015), Vector3(0, -0.09, guard_z - 0.03), edge)
	if category == 1:
		# Slide serrations, ejection port, grip panels and rear sight notch.
		for side in [-1, 1]:
			add(parts, Vector3(0.012, 0.12, 0.064), Vector3(side * 0.040, -0.13, length * 0.3), furniture)
			for groove in range(6):
				add(parts, Vector3(0.009, 0.07, 0.007), Vector3(side * 0.057, 0.009, length * 0.36 - groove * 0.012), dark)
			add(parts, Vector3(0.018, 0.03, 0.035), Vector3(side * 0.028, 0.084, length * 0.40), dark)
			add(parts, Vector3(0.008, 0.008, 0.006), Vector3(side * 0.028, 0.088, length * 0.40 + 0.02), Color("e7e5ca"))
		add(parts, Vector3(0.06, 0.009, 0.055), Vector3(0.012, 0.078, -0.018), dark)
		add(parts, Vector3(0.009, 0.009, 0.055), Vector3(0.058, 0.015, -0.018), dark)
		add(parts, Vector3(0.082, 0.018, 0.105), Vector3(0, -0.213, length * 0.3), dark)
		add(parts, Vector3(0.055, 0.055, 0.022), Vector3(0, 0.025, -length / 2 - barrel), edge)
		add(parts, Vector3(0.024, 0.024, 0.025), Vector3(0, 0.025, -length / 2 - barrel - 0.013), dark)
	elif category == 3:
		var width: float = 0.12 if p[7] in ["open_tube", "compact"] else 0.20
		for z in [-length * 0.28, length * 0.28]:
			add(parts, Vector3(width + 0.013, width + 0.013, 0.025), Vector3(0, 0.045, z), metal.lightened(0.18))
		for side in [-1, 1]:
			add(parts, Vector3(0.006, 0.055, 0.12), Vector3(side * (width / 2 + 0.009), 0.06, 0.08), Color("cec5a0"))
			for stripe in range(3):
				add(parts, Vector3(0.008, 0.005, 0.07), Vector3(side * (width / 2 + 0.014), 0.045 + stripe * 0.012, 0.08), dark)
		add(parts, Vector3(0.12, 0.055, 0.22), Vector3(0, -width / 2 - 0.015, 0.13), dark)
	else:
		# Handguard ribs and vents are visible from the first-person angle.
		for rib in range(6):
			var z: float = -length * 0.21 - rib * length * 0.065
			for side in [-1, 1]:
				add(parts, Vector3(0.008, 0.032, 0.025), Vector3(side * 0.06, 0.012, z), furniture.darkened(0.30))
			add(parts, Vector3(0.09, 0.007, 0.013), Vector3(0, 0.045, z), furniture.lightened(0.18))
		add(parts, Vector3(0.012, 0.035, 0.095), Vector3(0.060, 0.019, 0.015), dark)
		add(parts, Vector3(0.05, 0.02, 0.035), Vector3(0.082, 0.012, 0.06), edge)
		if p[6] not in ["spade", "skeleton", "thumbhole"]:
			add(parts, Vector3(0.108, 0.16, 0.022), Vector3(0, -0.025, length / 2 + (0.155 if p[6] == "bullpup" else 0.20)), dark)
			add(parts, Vector3(0.082, 0.018, 0.12), Vector3(0, 0.06, length / 2 + 0.07), furniture.lightened(0.18))
		if p[5] in ["box", "rear", "curve"]:
			for rib in range(4):
				var mag_z: float = 0.17 if p[5] == "rear" else -0.04
				if p[5] == "curve":
					mag_z = -0.03 - rib * rib * 0.008
				add(parts, Vector3(0.073, 0.009, 0.075), Vector3(0, -0.10 - rib * 0.04, mag_z), metal.lightened(0.12))
		var muzzle_z: float = -length / 2 - barrel
		add(parts, Vector3(0.06, 0.06, 0.045), Vector3(0, 0.025, muzzle_z), metal)
		add(parts, Vector3(0.027, 0.027, 0.008), Vector3(0, 0.025, muzzle_z - 0.026), dark)
		if category != 4:
			add(parts, Vector3(0.022, 0.065, 0.022), Vector3(0, 0.067, muzzle_z + 0.07), dark)
			for side in [-1, 1]:
				add(parts, Vector3(0.015, 0.06, 0.025), Vector3(side * 0.022, 0.065, muzzle_z + 0.07), metal)
	if category == 4 or p[7] == "scope":
		# Scope adjustment turrets, mounting rings and a glass highlight.
		add(parts, Vector3(0.052, 0.043, 0.05), Vector3(0, 0.225, 0), edge)
		add(parts, Vector3(0.035, 0.05, 0.05), Vector3(0.06, 0.17, 0), edge)
		for z in [-0.075, 0.075]:
			add(parts, Vector3(0.09, 0.09, 0.018), Vector3(0, 0.17, z), metal.lightened(0.12))
		add(parts, Vector3(0.018, 0.025, 0.005), Vector3(-0.02, 0.19, 0.172), Color("b5e6ea"))

static func muzzle_position(category: int, index: int) -> Vector3:
	var p: Array = PROFILES[category][index]
	if category == 3:
		return Vector3(0,0.045,-float(p[3])/2 - (0.36 if p[7] == "warhead" else 0.06))
	return Vector3(0,0.025,-float(p[3])/2-float(p[4])-0.034)

static func melee_geometry(index: int) -> Array:
	var p: Array = PROFILES[5][index]
	var parts: Array = []
	var steel := Color(p[1])
	var handle := Color(p[2])
	var length: float = p[3]
	add(parts,Vector3(0.06,0.07,0.20),Vector3(0,0,0.10),handle)
	add(parts,Vector3(0.075,0.085,0.025),Vector3(0,0,0.21),steel.darkened(0.3))
	for side in [-1,1]:
		for z in [0.05,0.15]:
			add(parts,Vector3(0.008,0.018,0.018),Vector3(side*0.034,0,z),steel.lightened(0.2))
	for i in range(6):
		add(parts,Vector3(0.065,0.075,0.01),Vector3(0,0,0.025+i*0.028),handle.darkened(0.25))
	if p[7] == "axe":
		add(parts,Vector3(0.045,0.055,length),Vector3(0,0,-length/2),handle)
		add(parts,Vector3(0.26,0.04,0.13),Vector3(0.075,0,-length+0.055),steel)
		add(parts,Vector3(0.045,0.025,0.16),Vector3(0.22,0,-length+0.055),steel.lightened(0.3))
	elif p[7] == "bat":
		add(parts,Vector3(0.095,0.095,length),Vector3(0,0,-length/2),handle.lightened(0.25))
		add(parts,Vector3(0.075,0.075,0.07),Vector3(0,0,-length-0.025),handle)
	elif p[7] == "crowbar":
		add(parts,Vector3(0.035,0.045,length),Vector3(0,0,-length/2),steel)
		add(parts,Vector3(0.12,0.045,0.05),Vector3(0.045,0,-length),steel)
	else:
		var width: float = 0.10 if p[7] in ["blade","kukri"] else 0.065
		add(parts,Vector3(0.14,0.05,0.025),Vector3.ZERO,steel.darkened(0.3))
		add(parts,Vector3(width,0.025,length),Vector3(0,0,-length/2),steel)
		add(parts,Vector3(width * 0.4,0.018,0.08),Vector3(-width*0.15,0,-length-0.025),steel.lightened(0.35))
		add(parts,Vector3(0.012,0.015,length*0.9),Vector3(width/2,0,-length/2),steel.lightened(0.4))
	return parts

static func _finish_details(parts: Array, category: int, index: int) -> void:
	var p: Array = PROFILES[category][index]
	var steel := Color(p[1])
	for side in [-1,1]:
		for z in [-0.1,0.08]:
			add(parts,Vector3(0.009,0.014,0.014),Vector3(side*0.061,-0.015,z),steel.lightened(0.35))
		add(parts,Vector3(0.008,0.014,0.065),Vector3(side*0.064,0.025,0.04),steel.darkened(0.5))
		for i in range(3):
			add(parts,Vector3(0.006,0.007,0.007),Vector3(side*0.07,0.025,-0.015+i*0.012),Color("b9b7a4"))
	if category in [0,2,4]:
		add(parts,Vector3(0.025,0.025,0.06),Vector3(-0.073,-0.01,0.1),steel.darkened(0.25))
		add(parts,Vector3(0.10,0.025,0.045),Vector3(0,-0.05,float(p[3])*0.45),Color("4a5354"))