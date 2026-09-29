extends Control
var combat: Node

func _draw() -> void:
	if not is_instance_valid(combat):
		return
	var center := size / 2
	if combat.hit_time > 0:
		for direction in [Vector2(1,1), Vector2(-1,1), Vector2(1,-1), Vector2(-1,-1)]:
			draw_line(center + direction * 7, center + direction * 14, combat.hit_color, 3)
	if not combat.aiming:
		if combat.armory.selected_category >= 0 and not combat.armory.is_open:
			var spread: float = deg_to_rad(combat.current_spread_degrees())
			var gap: float = clampf(tan(spread) / tan(deg_to_rad(combat.camera.fov / 2)) * size.y / 2, 5, 150)
			for axis in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
				draw_line(center + axis * gap, center + axis * (gap + 9), Color("eaf2dc"), 2)
			draw_circle(center, 1.5, Color("eaf2dc"))
		return
	var kind: String = combat.sight_kind()
	var ink := Color("121b20")
	if kind in ["scope", "pso", "ring"]:
		_draw_optic(center, ink)
	elif kind == "launcher":
		draw_rect(Rect2(center - Vector2(65, 55), Vector2(130,110)), ink, false, 4)
		for i in range(4):
			draw_line(center + Vector2(-25, i * 12), center + Vector2(25, i * 12), ink, 2)
		draw_line(center + Vector2(0,-20), center + Vector2(0,45), ink, 2)
	else:
		pass # Iron sights are now actual geometry mounted on the weapon.

func _draw_optic(center: Vector2, ink: Color) -> void:
	var radius: float = minf(size.x, size.y) * 0.40
	var outside: float = size.length()
	for i in range(128):
		var a := Vector2.from_angle(TAU * i / 128)
		var b := Vector2.from_angle(TAU * (i + 1) / 128)
		draw_colored_polygon(PackedVector2Array([center + a * radius, center + a * outside, center + b * outside, center + b * radius]), Color("080c10"))
	# Concentric eyepiece rings and a restrained edge shadow leave the center clear.
	draw_arc(center, radius + 12, 0, TAU, 128, Color("1f282d"), 15, true)
	draw_arc(center, radius + 4, 0, TAU, 128, Color("576165"), 3, true)
	for ring in range(7):
		draw_arc(center, radius - ring * 2, 0, TAU, 128, Color(0.03,0.06,0.07,0.27 - ring * 0.032), 2, true)
	draw_arc(center, radius + 9, PI * 1.10, PI * 1.72, 50, Color("718186"), 1.5, true)
	var unit: float = radius / 10.0
	var design: String = combat.scope_style()
	if design == "aug_ring":
		draw_arc(center, unit * 0.85, 0, TAU, 64, ink, 2.5, true)
		draw_circle(center,2.0,ink)
	elif design == "pu_post":
		draw_line(center + Vector2(-radius,0), center + Vector2(-unit,0), ink, 3)
		draw_line(center + Vector2(unit,0), center + Vector2(radius,0), ink, 3)
		draw_colored_polygon(PackedVector2Array([center,center + Vector2(-4,unit),center + Vector2(-4,radius),center + Vector2(4,radius),center + Vector2(4,unit)]), ink)
	elif design == "pgo":
		# Launcher grid is distinct from the SVD's chevrons.
		for row in range(5):
			var y: float = row * unit * 0.65
			draw_line(center + Vector2(-unit*2.5,y),center + Vector2(unit*2.5,y),ink,1.2,true)
			draw_string(ThemeDB.fallback_font,center + Vector2(unit*2.7,y+4),str(row+2),HORIZONTAL_ALIGNMENT_LEFT,-1,12,ink)
		for column in range(-2,3):
			draw_line(center + Vector2(column*unit,-unit*0.5),center + Vector2(column*unit,unit*2.6),ink,1.2,true)
		draw_polyline(PackedVector2Array([center+Vector2(-6,6),center,center+Vector2(6,6)]),ink,1.5,true)
	elif design == "pso":
		for row in range(4):
			var y: float = row * unit
			draw_polyline(PackedVector2Array([center + Vector2(-8,y+6),center + Vector2(0,y),center + Vector2(8,y+6)]), ink, 1.5, true)
		for side in [-1,1]:
			draw_line(center + Vector2(side * unit,0),center + Vector2(side * unit * 5,0),ink,1.2,true)
			for tick in range(1,6):
				draw_line(center + Vector2(side * unit * tick,-4),center + Vector2(side * unit * tick,4),ink,1.2,true)
		# Stylized ranging curve, a recognizable feature of these reticles.
		var curve := PackedVector2Array()
		for i in range(30):
			var x: float = -5 * unit + i * unit * 0.1
			curve.append(center + Vector2(x, 3.5 * unit - 1.5 * unit / (1.0 + float(i) / 29 * 3.0)))
		draw_polyline(curve,ink,1.2,true)
		draw_line(center + Vector2(-5*unit,3.5*unit),center + Vector2(-2*unit,3.5*unit),ink,1.2,true)
		for number in range(5):
			var x: float = -5*unit + number * unit * 0.65
			var y: float = 3.5*unit - 1.5*unit / (1.0 + number * 0.7)
			draw_line(center+Vector2(x,y),center+Vector2(x,y-5),ink,1.2,true)
			draw_string(ThemeDB.fallback_font,center+Vector2(x-3,y-8),str(2+number*2),HORIZONTAL_ALIGNMENT_LEFT,-1,10,ink)
		draw_string(ThemeDB.fallback_font,center+Vector2(-5*unit,4.1*unit),"1.7",HORIZONTAL_ALIGNMENT_LEFT,-1,11,ink)
	elif design == "g36":
		draw_arc(center,unit * 0.70,0,TAU,48,ink,1.5,true)
		draw_circle(center,1.5,ink)
		draw_line(center + Vector2(0,unit), center + Vector2(0,unit * 5),ink,1.2,true)
		for i in range(1,5):
			draw_line(center + Vector2(-14 + i*2,i*unit),center + Vector2(14 - i*2,i*unit),ink,1.2,true)
	else:
		draw_line(center - Vector2(radius,0),center + Vector2(radius,0),ink,1.2,true)
		draw_line(center - Vector2(0,radius),center + Vector2(0,radius),ink,1.2,true)
		for axis in [Vector2.LEFT,Vector2.RIGHT,Vector2.DOWN,Vector2.UP]:
			draw_line(center + axis * radius * 0.62,center + axis * radius,ink,3)
		if design in ["mil_dot","mil_tree"]:
			for i in range(-5,6):
				if i == 0:
					continue
				if design == "mil_dot":
					draw_arc(center + Vector2(i*unit,0),2.5,0,TAU,16,ink,1,true)
					draw_arc(center + Vector2(0,i*unit),2.5,0,TAU,16,ink,1,true)
				else:
					draw_line(center + Vector2(i*unit,-4),center + Vector2(i*unit,4),ink,1.2,true)
					draw_line(center + Vector2(-4,i*unit),center + Vector2(4,i*unit),ink,1.2,true)
			if design == "mil_tree":
				for row in range(1,6):
					for column in range(-row,row+1):
						draw_circle(center + Vector2(column * unit,row * unit),1.3,ink)
					draw_string(ThemeDB.fallback_font,center + Vector2(row*unit + 9,row*unit + 4),str(row),HORIZONTAL_ALIGNMENT_LEFT,-1,11,ink)
	if design == "mil_tree":
		draw_circle(center,1.5,ink)
		for tick in range(-25,26):
			if tick == 0 or tick % 5 == 0:
				continue
			var spacing: float = unit / 5
			draw_line(center+Vector2(tick*spacing,-2),center+Vector2(tick*spacing,2),ink,1.0,true)
			draw_line(center+Vector2(-2,tick*spacing),center+Vector2(2,tick*spacing),ink,1.0,true)
		for row in range(1,6):
			for dot in range(-row*5,row*5+1):
				if dot % 5 != 0:
					draw_circle(center + Vector2(dot*unit/5,row*unit),0.7,ink)
	var title: String = combat.optic_name() + " / %.1fx" % combat.optic_magnification()
	draw_string(ThemeDB.fallback_font,center + Vector2(-radius, -radius - 26),title,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("97a8ae"))



func _draw_iron_sights(center: Vector2, kind: String) -> void:
	var scale_factor: float = minf(size.x/1100.0,size.y/700.0)
	var weapon: Node3D = combat.armory.weapon
	# Project a point attached to the actual weapon, including ADS motion and recoil.
	var anchor: Vector3 = weapon.to_global(Vector3(0,0.067 / weapon.scale.y,0))
	var projected: Vector2 = combat.camera.unproject_position(anchor)
	var right: Vector2 = combat.camera.unproject_position(weapon.to_global(Vector3(0.1,0.067 / weapon.scale.y,0)))
	var depth: float = maxf(0.1,-combat.camera.to_local(anchor).z)
	scale_factor *= (0.72 / depth) * (weapon.scale.y / 0.85)
	draw_set_transform(projected,(right-projected).angle(),Vector2.ONE*scale_factor)
	var metal := Color("222b30")
	var edge := Color("657079")
	var dark := Color("10171b")
	var category: int = combat.armory.selected_category
	var index: int = combat.armory.selected_index
	if kind == "aperture":
		# Rear aperture with a thinner inner rim; open space around the front post.
		draw_arc(Vector2(0,6),48,0,TAU,80,dark,4,true)
		draw_arc(Vector2(0,6),51,0,TAU,80,edge,1.5,true)
		draw_arc(Vector2(0,6),45,0,TAU,80,metal,1.0,true)
		for side in [-1,1]:
			draw_colored_polygon(PackedVector2Array([Vector2(side*26,33),Vector2(side*32,15),Vector2(side*35,17),Vector2(side*30,35)]),metal)
	else:
		# Sculpted rear sight with an actual center notch rather than flat bars.
		for side in [-1,1]:
			var points := PackedVector2Array([Vector2(side*26,0),Vector2(side*46,0),Vector2(side*50,10),Vector2(side*50,22),Vector2(side*26,22)])
			draw_colored_polygon(points,dark)
			draw_line(Vector2(side*27,0),Vector2(side*44,0),edge,1.5,true)
		if category == 0:
			# AK front-sight protective ears.
			draw_polyline(PackedVector2Array([Vector2(-16,23),Vector2(-19,8),Vector2(-13,2)]),metal,2,true)
			draw_polyline(PackedVector2Array([Vector2(16,23),Vector2(19,8),Vector2(13,2)]),metal,2,true)
	# Front post tip marks the shot center. Its body extends below the target.
	draw_colored_polygon(PackedVector2Array([Vector2(-2,0),Vector2(2,0),Vector2(3,31),Vector2(-3,31)]),dark)
	draw_line(Vector2(-3,0),Vector2(3,0),edge,1,true)
	if category == 1:
		if index == 2:
			# Glock-style white rear U and front dot.
			draw_polyline(PackedVector2Array([Vector2(-30,7),Vector2(-30,25),Vector2(30,25),Vector2(30,7)]),Color("dddcc9"),2,true)
			draw_circle(Vector2(0,7),2.2,Color("f0eeda"))
		elif index not in [1,6,7]:
			for x in [-37,0,37]:
				draw_circle(Vector2(x,7),2.2,Color("e8e5c8"))
	draw_set_transform(Vector2.ZERO)

