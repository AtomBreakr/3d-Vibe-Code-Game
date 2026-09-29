extends CharacterBody3D
const Catalog = preload("res://weapon_catalog.gd")
const Damage = preload("res://damage_data.gd")
var manager: Node
var target: Node3D
var spawn_point: Vector3
var target_number: int
var regeneration = preload("res://regeneration.gd").new()
var health := 100
var shield := 50
var category := 0
var weapon_index := 0
var secondary_index := 0
var loaded := 0
var reload_time := 0.0
var shot_time := 1.0
var repath := 0.0
var dead_time := 0.0
var route: Array[Vector3] = []
var visual: Node3D
var label: Label3D
var collider: CollisionShape3D
var shots := 0
var gun: Node3D
var using_sidearm := false
var legs: Array[Node3D] = []
var arms: Array[Node3D] = []
var walk_phase := 0.0

func _ready() -> void:
	add_to_group("enemies")
	floor_snap_length = 0.45
	collider = CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.8
	collider.shape = capsule
	add_child(collider)
	reset_bot()

func reset_bot() -> void:
	regeneration.reset()
	global_position = manager.pick_spawn(self)
	velocity = Vector3.ZERO
	health = 100
	shield = 50
	using_sidearm = false
	category = [0,2,4].pick_random()
	weapon_index = randi_range(0,9)
	secondary_index = randi_range(0,9)
	if get_node("/root/GameSettings").mode() == 1:
		var score = manager.get_parent().get_node("Scoreboard")
		var kills: int = score.stats[target_number].kills if score.stats.has(target_number) else 0
		var item: Array = get_node("/root/GameSettings").stage(kills)
		category = item[0]
		weapon_index = item[1]
	loaded = 8 if category == 4 else 20
	reload_time = 0
	shot_time = randf_range(0.7,1.5)
	route.clear()
	if is_instance_valid(visual):
		visual.queue_free()
	visual = Node3D.new()
	add_child(visual)
	var shop = manager.get_parent().get_node("Vendors")
	shop._part(visual,Vector3(0.65,0.65,0.38),Vector3(0,0.22,0),Color("438da9") if get_node("/root/GameSettings").mode() == 2 and get_node("/root/GameSettings").team(target_number) == 0 else Color("9f4942"))
	shop._part(visual,Vector3(0.42,0.42,0.42),Vector3(0,0.7,0),Color("d3aa7e"))
	preload("res://model_details.gd").character(visual,true)
	legs.clear()
	arms.clear()
	walk_phase = 0
	for side in [-1,1]:
		var hip := Node3D.new()
		visual.add_child(hip)
		hip.position = Vector3(side*0.2,-0.15,0)
		legs.append(hip)
		shop._part(hip,Vector3(0.23,0.62,0.25),Vector3(0,-0.31,0),Color("343d49"))
		shop._part(hip,Vector3(0.25,0.13,0.38),Vector3(0,-0.685,-0.06),Color("232b32"))
		var shoulder := Node3D.new()
		visual.add_child(shoulder)
		shoulder.position = Vector3(side*0.43,0.45,0)
		arms.append(shoulder)
		shop._part(shoulder,Vector3(0.18,0.6,0.2),Vector3(0,-0.3,-0.1),Color("438da9") if get_node("/root/GameSettings").mode() == 2 and get_node("/root/GameSettings").team(target_number) == 0 else Color("9f4942"))
	gun = Node3D.new()
	visual.add_child(gun)
	gun.position = Vector3(0.22,0.12,-0.4)
	gun.scale = Vector3.ONE*0.7
	for part in Catalog.geometry(category,weapon_index):
		shop._part(gun,part[0],part[1],part[2])
	label = Label3D.new()
	visual.add_child(label)
	label.position.y = 1.25
	label.pixel_size = 0.006
	label.font_size = 24
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.text = "RAIDER %d / %s\nSidearm: %s" % [target_number-100,Catalog.PROFILES[category][weapon_index][0],Catalog.PROFILES[1][secondary_index][0]]
	collider.set_deferred("disabled",false)

func _physics_process(delta: float) -> void:
	if not manager.get_parent().get_meta("round_active",true):
		_animate_walk(delta,0)
		return
	regeneration.advance(self,delta)
	if health <= 0:
		dead_time -= delta
		if dead_time <= 0:
			reset_bot()
		return
	target = manager.opponent(self)
	if not is_instance_valid(target) or manager.grace > 0:
		_animate_walk(delta,0)
		return
	shot_time -= delta
	reload_time = maxf(0,reload_time-delta)
	var distance: float = global_position.distance_to(target.global_position)
	var close_range: bool = distance < 6.0 and get_node("/root/GameSettings").mode() != 1
	if close_range != using_sidearm:
		using_sidearm = close_range
		for part in gun.get_children():
			part.queue_free()
		var shop = manager.get_parent().get_node("Vendors")
		for part in Catalog.geometry(1 if using_sidearm else category,secondary_index if using_sidearm else weapon_index):
			shop._part(gun,part[0],part[1],part[2])
	var sees: bool = distance < 28 and can_see_player()
	repath -= delta
	if repath <= 0:
		repath = randf_range(1.2,2.0)
		var destination: Vector3 = target.global_position if distance < 32 else manager.world(manager.cells.pick_random())
		route = manager.path(global_position,destination)
	var direction := Vector3.ZERO
	if not sees or distance > 13:
		while not route.is_empty() and Vector2(route[0].x-global_position.x,route[0].z-global_position.z).length() < 0.5:
			route.pop_front()
		if not route.is_empty():
			direction = (route[0]-global_position)
			direction.y = 0
			direction = direction.normalized()
	velocity.x = direction.x*2.7
	velocity.z = direction.z*2.7
	velocity.y -= 20*delta
	# Step over sidewalk curbs while following the route.
	if is_on_floor() and direction.length_squared() > 0:
		var motion := direction*0.2
		if test_move(global_transform,motion):
			var raised := global_transform
			raised.origin.y += 0.3
			if not test_move(global_transform,Vector3.UP*0.3) and not test_move(raised,motion):
				global_position.y += 0.3
	var previous_position := global_position
	move_and_slide()
	_animate_walk(delta,global_position.distance_to(previous_position) / maxf(delta,0.001))
	var facing: Vector3 = target.global_position-global_position if sees else direction
	facing.y = 0
	if facing.length_squared() > 0.01:
		visual.look_at(visual.global_position+facing)
	if sees and shot_time <= 0 and reload_time <= 0:
		shoot()

func can_see_player() -> bool:
	return is_instance_valid(target) and can_see(target)

func can_see(candidate: Node3D) -> bool:
	var origin := global_position+Vector3.UP*0.55
	var aim: Vector3 = candidate.global_position+Vector3.UP*0.45
	if candidate == manager.player:
		aim = manager.player.camera.global_position
	var query := PhysicsRayQueryParameters3D.create(origin,aim)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.collider == candidate
func shoot() -> void:
	if not can_see_player():
		return
	if loaded <= 0:
		reload_time = 2.5
		loaded = 8 if category == 4 else 20
		return
	loaded -= 1
	shots += 1
	shot_time = randf_range(1.3,1.9) if category == 4 else randf_range(0.38,0.65)
	var origin := global_position+Vector3.UP*0.5
	var aim: Vector3 = target.global_position + Vector3.UP*0.15
	if target == manager.player and manager.player.crouching:
		aim.y -= 0.45
	var spread: float = maxf(0.3,origin.distance_to(aim)*0.055)
	aim += Vector3(randf_range(-spread,spread),randf_range(-spread,spread),randf_range(-spread,spread))
	var query := PhysicsRayQueryParameters3D.create(origin,origin+(aim-origin).normalized()*40)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	var end: Vector3 = hit.position if not hit.is_empty() else query.to
	var combat = manager.get_parent().get_node("Armory/Combat")
	var tracer = combat._cube(Vector3(0.025,0.025,origin.distance_to(end)),(origin+end)/2,Color("ff8260"))
	tracer.look_at(end)
	combat._expire(tracer,0.07)
	if not hit.is_empty():
		var amount: int = clampi(roundi(Damage.BASE[1 if using_sidearm else category][secondary_index if using_sidearm else weapon_index]*0.45),10,40)
		if hit.collider == manager.player:
			manager.get_parent().get_node("Vitals").take_damage(amount,target_number)
		elif hit.collider is Node and hit.collider.is_in_group("enemies"):
			hit.collider.take_damage(amount,target_number)
func take_damage(amount: int, attacker_id: int = 0) -> Dictionary:
	if not get_node("/root/GameSettings").hostile(attacker_id,target_number):
		return {}
	if not manager.get_parent().get_meta("round_active",true):
		return {}
	if health <= 0 or amount <= 0:
		return {}
	regeneration.reset()
	var absorbed := mini(shield,amount)
	var hurt := mini(health,amount-absorbed)
	shield -= absorbed
	health -= hurt
	if health == 0:
		manager.get_parent().get_node("Scoreboard").record_death(target_number,attacker_id)
		dead_time = 12.0
		visual.hide()
		collider.set_deferred("disabled",true)
	return {"total":absorbed+hurt,"shield":absorbed,"health":hurt,"broken":absorbed>0 and shield==0,"eliminated":health==0,"target":target_number}

func is_headshot(point: Vector3) -> bool:
	var local: Vector3 = visual.to_local(point)
	return local.y >= 0.49 and local.y <= 0.93 and absf(local.x) <= 0.23

func _animate_walk(delta: float, actual_speed: float) -> void:
	var moving: bool = actual_speed > 0.15 and is_on_floor()
	if moving:
		walk_phase += actual_speed * delta * 4.0
	var stride: float = sin(walk_phase) * 0.48 if moving else 0.0
	for i in range(legs.size()):
		var side: float = 1.0 if i == 0 else -1.0
		legs[i].rotation.x = lerpf(legs[i].rotation.x,stride*side,minf(1,delta*18))
		arms[i].rotation.x = lerpf(arms[i].rotation.x,-stride*side*0.45,minf(1,delta*18))
	visual.position.y = lerpf(visual.position.y,absf(sin(walk_phase))*0.025 if moving else 0.0,minf(1,delta*18))
	gun.position.y = 0.12 + (sin(walk_phase*2)*0.012 if moving else 0.0)
func refresh_gun() -> void:
	for part in gun.get_children():
		gun.remove_child(part)
		part.queue_free()
	var shop = manager.get_parent().get_node("Vendors")
	for part in Catalog.geometry(category,weapon_index):
		shop._part(gun,part[0],part[1],part[2])
	label.text = "RAIDER %d / %s" % [target_number-100,Catalog.PROFILES[category][weapon_index][0]]