extends Node
const Catalog = preload("res://weapon_catalog.gd")
var armory: CanvasLayer
var player: CharacterBody3D
var camera: Camera3D
var aiming: bool = false
var trigger: bool = false
var pending_shot: bool = false
var cooldown: float = 0
var recoil: float = 0
var hit_time: float = 0
var shots_fired: int = 0
var rockets: Array = []
var sight: Control
var hud: Label
var effects: Array[Node3D] = []
var audio: AudioStreamPlayer
const Damage = preload("res://damage_data.gd")
var damage_hud: Label
var damage_time: float = 0
var damage_messages: Array[String] = []
var hit_color := Color("ffdd82")
const Ammo = preload("res://ammo_data.gd")
var ammo_states: Dictionary = {}
var reload_remaining: float = 0
var reload_key: String = ""
var ammo_hud: Label
const Handling = preload("res://weapon_handling.gd")
var recoil_offset := Vector2.ZERO
var spread_bloom: float = 0
var time_since_shot: float = 10
var burst_shot: int = 0
var aim_blend: float = 0
var spread_rng := RandomNumberGenerator.new()
var last_shot_direction := Vector3.FORWARD
var last_muzzle_position := Vector3.ZERO
var last_tracer_origin := Vector3.ZERO
var melee_swing: float = 0
var melee_elapsed: float = -1
var melee_duration: float = 0.65
var melee_impact_done: bool = false

func _ready() -> void:
	spread_rng.randomize()
	armory = get_parent()
	player = armory.player
	camera = player.camera
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	sight = Control.new()
	sight.set_script(preload("res://sight_overlay.gd"))
	sight.combat = self
	sight.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(sight)
	hud = Label.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	hud.position = Vector2(24, -65)
	hud.add_theme_font_size_override("font_size", 18)
	hud.add_theme_color_override("font_shadow_color", Color.BLACK)
	hud.add_theme_constant_override("shadow_offset_x", 2)
	hud.add_theme_constant_override("shadow_offset_y", 2)
	sight.add_child(hud)
	ammo_hud = Label.new()
	sight.add_child(ammo_hud)
	ammo_hud.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	ammo_hud.offset_left = -320
	ammo_hud.offset_top = -105
	ammo_hud.offset_right = -24
	ammo_hud.offset_bottom = -20
	ammo_hud.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ammo_hud.add_theme_font_size_override("font_size", 24)
	ammo_hud.add_theme_color_override("font_shadow_color", Color.BLACK)
	ammo_hud.add_theme_constant_override("shadow_offset_x", 2)
	ammo_hud.add_theme_constant_override("shadow_offset_y", 2)
	damage_hud = Label.new()
	sight.add_child(damage_hud)
	damage_hud.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	damage_hud.offset_left = 28
	damage_hud.offset_top = 24
	damage_hud.offset_right = 370
	damage_hud.offset_bottom = 140
	damage_hud.add_theme_font_size_override("font_size", 16)
	damage_hud.add_theme_color_override("font_shadow_color", Color.BLACK)
	damage_hud.add_theme_constant_override("shadow_offset_x", 2)
	damage_hud.add_theme_constant_override("shadow_offset_y", 2)
	damage_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	audio = AudioStreamPlayer.new()
	audio.volume_db = -18
	add_child(audio)

func cancel_input() -> void:
	melee_elapsed = -1
	melee_swing = 0
	melee_impact_done = false
	_clear_handling()
	reload_remaining = 0
	reload_key = ""
	trigger = false
	pending_shot = false
	aiming = false
	recoil = 0
	if is_instance_valid(camera):
		camera.fov = 75
	if is_instance_valid(armory.weapon):
		armory.weapon.visible = true

func _unhandled_input(event: InputEvent) -> void:
	if player.get_meta("explosive_equipped", false):
		return
	if armory.is_open or not player.controls_active or armory.selected_category < 0:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.is_action("reload"):
		start_reload()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			trigger = event.pressed
			pending_shot = event.pressed
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			aiming = event.pressed and reload_remaining <= 0 and armory.selected_category != 5
			get_viewport().set_input_as_handled()

func sight_kind() -> String:
	var category: int = armory.selected_category
	var index: int = armory.selected_index
	if category == 4:
		return "pso" if index == 4 else "scope"
	if category == 0 and index in [4,6]:
		return "ring" if index == 4 else "scope"
	if category == 3:
		return "pso" if index in [0,6] else "launcher"
	if category == 1 or (category == 0 and index in [0,7]):
		return "notch"
	return "aperture"

func _process(delta: float) -> void:
	if armory.is_open or not player.controls_active:
		cancel_input()
	recoil = move_toward(recoil, 0, delta * 0.35)
	hit_time = maxf(0, hit_time - delta)
	damage_time = maxf(0, damage_time - delta)
	damage_hud.visible = damage_time > 0 and not armory.is_open
	if damage_time == 0:
		damage_messages.clear()
	var optical: bool = sight_kind() in ["scope", "pso", "ring"]
	var zoom: float = scope_fov()
	camera.fov = lerpf(camera.fov, zoom if aiming and optical else (58.0 if aiming else 75.0), minf(1, delta * 18))
	if is_instance_valid(armory.weapon):
		armory.weapon.visible = not (aiming and optical) and not player.get_meta("explosive_equipped", false)
		var base_scale: float = 0.65 if armory.selected_category in [2,3,4] else 0.85
		var view_scale: float = base_scale * (0.82 if aiming and not optical else 1.0)
		armory.weapon.scale = armory.weapon.scale.lerp(Vector3.ONE * view_scale,minf(1,delta*20))
		# Use the aligned sight picture while aiming; restore modeled sights at the hip.
		for component in armory.weapon.get_children():
			if component is MeshInstance3D and component.position.y >= 0.06:
				component.visible = not (aiming and not optical and armory.selected_category != 3)
		var iron: bool = sight_kind() in ["notch","aperture"] and armory.selected_category != 5
		if iron and not armory.weapon.has_node("AlignedSights"):
			preload("res://iron_sights.gd").build(armory.weapon,armory.selected_category,armory.selected_index)
		if armory.weapon.has_node("AlignedSights"):
			armory.weapon.get_node("AlignedSights").visible = aiming and iron
		var sight_height: float = preload("res://iron_sights.gd").height(armory.selected_category,armory.selected_index)
		var pose := Vector3(0, -sight_height*armory.weapon.scale.y, -0.86) if aiming else Vector3(0.27,-0.23,-0.68)
		if aiming and optical:
			pose.y = -Catalog.muzzle_position(armory.selected_category,armory.selected_index).y * armory.weapon.scale.y
		if reload_remaining > 0:
			pose += Vector3(0, -0.3, 0.08)
		armory.weapon.position = armory.weapon.position.lerp(pose + Vector3(0, recoil * 0.2, recoil), minf(1, delta * 20))
		armory.weapon.rotation = Vector3(recoil * 0.7,0,0)
		if aiming and sight_kind() == "launcher":
			_clear_launcher_sight()
		if armory.selected_category == 5:
			_update_melee_pose()
	armory.get_parent().get_node("HUD/Crosshair").visible = armory.selected_category < 0 and not armory.is_open
	hud.visible = not armory.is_open
	hud.text = "B  Choose weapon" if armory.selected_category < 0 else str(Catalog.PROFILES[armory.selected_category][armory.selected_index][0]) + "  /  " + ("1 PRIMARY" if armory.active_slot == 0 else "2 SECONDARY") + "\nLMB Fire  |  RMB Aim  |  R Reload  |  1 / 2 / Wheel Switch"
	if armory.selected_category == 5:
		hud.text = str(Catalog.PROFILES[5][armory.selected_index][0]) + "  /  2 SECONDARY\nLMB Strike  |  1 / 2 / Wheel Switch"
	if get_node("/root/GameSettings").mode() == 1:
		var score = armory.get_parent().get_node("Scoreboard")
		var kills: int = score.stats[0].kills
		hud.text = "GUN GAME / WEAPON %d OF 10 / %s" % [mini(kills+1,10),Catalog.PROFILES[armory.selected_category][armory.selected_index][0]]
	_update_ammo_hud()
	sight.queue_redraw()

func _physics_process(delta: float) -> void:
	cooldown = maxf(0, cooldown - delta)
	_auto_reload()
	_advance_reload(delta)
	_update_handling(delta)
	_advance_melee(delta)
	if not armory.is_open and player.controls_active and armory.selected_category >= 0:
		var automatic: bool = armory.selected_category in [0,2]
		if cooldown <= 0 and (pending_shot or (trigger and automatic)):
			fire()
		pending_shot = false
	for i in range(rockets.size() - 1, -1, -1):
		var rocket: Dictionary = rockets[i]
		var start: Vector3 = rocket.node.position
		var finish: Vector3 = start + rocket.direction * delta * 32
		var query := PhysicsRayQueryParameters3D.create(start, finish)
		query.exclude = [player.get_rid()]
		var hit := player.get_world_3d().direct_space_state.intersect_ray(query)
		rocket.life -= delta
		if not hit.is_empty() or rocket.life <= 0:
			var point: Vector3 = hit.position if not hit.is_empty() else finish
			explode(point, rocket.damage, hit.collider if not hit.is_empty() else null)
			rocket.node.queue_free()
			rockets.remove_at(i)
		else:
			rocket.node.position = finish

func fire() -> void:
	if not armory.get_parent().get_meta("round_active",true):
		return
	if player.get_meta("explosive_equipped", false):
		return
	if armory.is_open or armory.selected_category < 0:
		return
	if reload_remaining > 0 or cooldown > 0 or not player.controls_active:
		return
	if armory.selected_category == 5:
		_melee_attack()
		return
	var state: Dictionary = ammo_state()
	if state.loaded <= 0:
		trigger = false
		return
	state.loaded -= 1
	shots_fired += 1
	var category: int = armory.selected_category
	cooldown = [0.12, 0.23, 0.09, 1.0, 0.85][category]
	recoil = 0.065 if category != 1 else 0.04
	_sound(category)
	var start := camera.global_position
	var direction := sample_shot_direction()
	last_shot_direction = direction
	var muzzle: Vector3 = armory.weapon.get_node("Muzzle").global_position
	last_muzzle_position = muzzle
	var obstruction_query := PhysicsRayQueryParameters3D.create(start,muzzle)
	obstruction_query.exclude = [player.get_rid()]
	var obstruction := player.get_world_3d().direct_space_state.intersect_ray(obstruction_query)
	if not obstruction.is_empty():
		muzzle = obstruction.position + obstruction.normal * 0.015
	last_tracer_origin = muzzle
	_apply_shot_recoil()
	if category == 3:
		var node := _cube(Vector3(0.12,0.12,0.28), muzzle, Color("e7ad57"))
		var aim_query := PhysicsRayQueryParameters3D.create(start,start + direction * 180)
		aim_query.exclude = [player.get_rid()]
		var aim_hit := player.get_world_3d().direct_space_state.intersect_ray(aim_query)
		var aim_point: Vector3 = aim_hit.position if not aim_hit.is_empty() else start + direction * 180
		direction = (aim_point - muzzle).normalized()
		node.look_at(node.position + direction)
		rockets.append({"node":node, "direction":direction, "life":4.0, "damage":Damage.BASE[category][armory.selected_index]})
		return
	var query := PhysicsRayQueryParameters3D.create(start, start + direction * 180)
	query.exclude = [player.get_rid()]
	var hit := player.get_world_3d().direct_space_state.intersect_ray(query)
	var end: Vector3 = hit.position if not hit.is_empty() else start + direction * 180
	var barrel_query := PhysicsRayQueryParameters3D.create(muzzle,end)
	barrel_query.exclude = [player.get_rid()]
	var barrel_hit := player.get_world_3d().direct_space_state.intersect_ray(barrel_query)
	if not barrel_hit.is_empty():
		hit = barrel_hit
		end = barrel_hit.position
	var tracer := _cube(Vector3(0.015,0.015,muzzle.distance_to(end)), (muzzle + end) / 2, Color("ffe5a0"))
	tracer.look_at(end)
	_expire(tracer, 0.045)
	var flash := _cube(Vector3(0.08,0.08,0.12), muzzle, Color("ffdb71"))
	_expire(flash, 0.05)
	if not hit.is_empty():
		# Permanent-looking impact marks belong on scenery, not moving characters.
		if hit.collider is StaticBody3D and not hit.collider.has_method("take_damage") and not hit.collider.is_in_group("vendors"):
			var mark := _cube(Vector3.ONE * 0.055, end + hit.normal * 0.025, Color("34302a"))
			_expire(mark, 8)
		_hit_target(hit.collider, Damage.BASE[category][armory.selected_index], hit.position)

func _hit_target(body: Object, amount: int, hit_position: Vector3 = Vector3.INF) -> void:
	if not body is Node or not (body.is_in_group("practice_targets") or body.is_in_group("enemies")) or not body.has_method("take_damage"):
		return
	var headshot: bool = hit_position != Vector3.INF and body.has_method("is_headshot") and body.is_headshot(hit_position)
	var result: Dictionary = body.take_damage(amount * 2 if headshot else amount)
	if result.is_empty():
		return
	hit_time = 0.22
	damage_time = 1.3
	hit_color = Color("80d5ff") if result.health == 0 else Color("ffe7b0")
	var notice: String = " / HEADSHOT" if headshot else ""
	if result.eliminated:
		notice += " / ELIMINATED"
		hit_color = Color("ff927a")
	elif result.broken:
		notice += " / SHIELD BROKEN"
	var line: String = "%d DMG  [T%d]%s\n%d shield + %d health" % [result.total, result.target, notice, result.shield, result.health]
	damage_messages.push_front(line)
	if damage_messages.size() > 2:
		damage_messages.pop_back()
	damage_hud.text = "\n".join(damage_messages)
	damage_hud.add_theme_color_override("font_color", hit_color)

func explode(point: Vector3, damage: int = 150, direct_hit: Object = null) -> void:
	# Direct hits always receive full damage, independent of impact height or cover checks.
	if is_instance_valid(direct_hit):
		_hit_target(direct_hit,damage)
	if armory.get_parent().has_node("Vitals"):
		armory.get_parent().get_node("Vitals").blast_damage(point, damage)
	var blast := _cube(Vector3.ONE * 0.3, point, Color("ffa04a"))
	var tween := create_tween()
	tween.tween_property(blast, "scale", Vector3.ONE * 9, 0.16)
	tween.tween_property(blast, "scale", Vector3.ZERO, 0.22)
	tween.tween_callback(blast.queue_free)
	for target in (get_tree().get_nodes_in_group("practice_targets") + get_tree().get_nodes_in_group("enemies")):
		if target == direct_hit:
			continue
		var distance: float = target.global_position.distance_to(point)
		if distance >= 4:
			continue
		# Cover blocks splash; direct/near hits get full damage.
		var toward: Vector3 = (target.global_position - point).normalized()
		var query := PhysicsRayQueryParameters3D.create(point + toward * 0.04, target.global_position)
		query.exclude = [player.get_rid()]
		var obstruction := player.get_world_3d().direct_space_state.intersect_ray(query)
		if not obstruction.is_empty() and obstruction.collider != target:
			continue
		var multiplier: float = 1.0 if distance <= 1.0 else lerpf(1.0, 0.25, (distance - 1) / 3)
		_hit_target(target, maxi(1, roundi(damage * multiplier)))
func _cube(size: Vector3, location: Vector3, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	node.material_override = mat
	armory.get_parent().add_child(node)
	node.position = location
	return node

func _expire(node: Node3D, seconds: float) -> void:
	var reference: WeakRef = weakref(node)
	get_tree().create_timer(seconds).timeout.connect(func():
		var effect = reference.get_ref()
		if is_instance_valid(effect):
			effect.queue_free())

func _sound(category: int) -> void:
	audio.stream = preload("res://gun_audio.gd").shot(category)
	audio.play()
func ammo_state() -> Dictionary:
	if armory.selected_category == 5:
		return {"loaded":0, "reserve":0, "capacity":0}
	var key := "%d:%d" % [armory.selected_category, armory.selected_index]
	if not ammo_states.has(key):
		var capacity: int = Ammo.CAPACITIES[armory.selected_category][armory.selected_index]
		ammo_states[key] = {"loaded": capacity, "reserve": capacity * Ammo.SPARE_LOADS, "capacity": capacity}
	return ammo_states[key]

func start_reload() -> void:
	if player.get_meta("explosive_equipped", false):
		return
	if armory.selected_category == 5:
		return
	if armory.is_open or not player.controls_active or armory.selected_category < 0 or reload_remaining > 0:
		return
	var state := ammo_state()
	if state.loaded >= state.capacity or state.reserve <= 0:
		return
	trigger = false
	pending_shot = false
	aiming = false
	reload_key = "%d:%d" % [armory.selected_category, armory.selected_index]
	reload_remaining = Ammo.RELOAD_SECONDS[armory.selected_category]

func _advance_reload(delta: float) -> void:
	if reload_remaining <= 0:
		return
	var current_key := "%d:%d" % [armory.selected_category, armory.selected_index]
	if armory.is_open or not player.controls_active or current_key != reload_key:
		reload_remaining = 0
		reload_key = ""
		return
	reload_remaining = maxf(0, reload_remaining - delta)
	if reload_remaining <= 0:
		var state: Dictionary = ammo_states[reload_key]
		var transfer: int = mini(state.capacity - state.loaded, state.reserve)
		state.loaded += transfer
		state.reserve -= transfer
		reload_key = ""
		trigger = false
		pending_shot = false

func _update_ammo_hud() -> void:
	ammo_hud.visible = not armory.is_open and armory.selected_category >= 0
	if not ammo_hud.visible:
		return
	if armory.selected_category == 5:
		ammo_hud.text = "MELEE
LEFT CLICK  STRIKE"
		return
	var state := ammo_state()
	var feed: String = "LOADED" if armory.selected_category == 3 else "MAG"
	if armory.selected_category == 2 and armory.selected_index <= 4 or (armory.selected_category == 2 and armory.selected_index == 6):
		feed = "BELT"
	var prompt := "R  RELOAD"
	if reload_remaining > 0:
		prompt = "RELOADING  %.1fs" % reload_remaining
	elif state.loaded == 0:
		prompt = "EMPTY — AUTO RELOAD" if state.reserve > 0 else "OUT OF AMMO — B TO SWITCH"
	elif state.reserve == 0:
		prompt = "NO RESERVE AMMO"
	ammo_hud.text = "%s  %d / %d\nRESERVE  %d\n%s" % [feed, state.loaded, state.capacity, state.reserve, prompt]
	ammo_hud.add_theme_color_override("font_color", Color("ffba78") if state.loaded == 0 else Color("edf5df"))

func current_spread_degrees() -> float:
	if armory.selected_category < 0 or armory.selected_category == 5:
		return 0.0
	var category: int = armory.selected_category
	var index: int = armory.selected_index
	var base: Array = Handling.BASE[category]
	var cone: float = lerpf(base[2], base[3], aim_blend) * Handling.ACCURACY[category][index]
	var moving: float = clampf(Vector2(player.velocity.x, player.velocity.z).length() / 6.0, 0, 1)
	cone *= 1.0 + moving * lerpf(0.85, 1.4, aim_blend)
	if not player.is_on_floor():
		cone *= 2.4
	return cone + spread_bloom * lerpf(1.0, 0.28, aim_blend)

func sample_shot_direction() -> Vector3:
	# Uniform disk sampling avoids square-shaped spread and center bias.
	var angle: float = spread_rng.randf() * TAU
	var radius: float = sqrt(spread_rng.randf()) * tan(deg_to_rad(current_spread_degrees()))
	var basis: Basis = camera.global_basis
	return (-basis.z + basis.x * cos(angle) * radius + basis.y * sin(angle) * radius).normalized()

func _apply_shot_recoil() -> void:
	var category: int = armory.selected_category
	var index: int = armory.selected_index
	var base: Array = Handling.BASE[category]
	var strength: float = Handling.KICK[category][index]
	var sustained: float = 1.0 + minf(burst_shot * 0.055, 0.55)
	var pitch: float = deg_to_rad(base[0] * strength * sustained * lerpf(1.0, 0.68, aim_blend))
	var pattern_index: int = (burst_shot + index % 4) % Handling.PATTERN.size()
	var sway: float = Handling.PATTERN[pattern_index] * (-1.0 if index % 2 else 1.0)
	var yaw: float = deg_to_rad(base[1] * strength * sway * sustained * lerpf(1.0, 0.75, aim_blend))
	var old_pitch: float = camera.rotation.x
	camera.rotation.x = clampf(old_pitch + pitch, deg_to_rad(-85), deg_to_rad(85))
	recoil_offset.x += camera.rotation.x - old_pitch
	var new_yaw: float = clampf(recoil_offset.y + yaw, deg_to_rad(-6), deg_to_rad(6))
	camera.rotation.y += new_yaw - recoil_offset.y
	recoil_offset.y = new_yaw
	recoil = minf(0.12, 0.035 + strength * 0.028)
	spread_bloom = minf(spread_bloom + base[4] * strength, 3.0)
	burst_shot += 1
	time_since_shot = 0

func _update_handling(delta: float) -> void:
	time_since_shot += delta
	aim_blend = move_toward(aim_blend, 1.0 if aiming and reload_remaining <= 0 else 0.0, delta * 5.5)
	if time_since_shot > 0.16:
		spread_bloom = move_toward(spread_bloom, 0.0, delta * 2.3)
		# Remove only the recoil offset; preserve the player's mouse corrections.
		var recovered: Vector2 = recoil_offset * (1.0 - exp(-delta * 7.0))
		camera.rotation.x = clampf(camera.rotation.x - recovered.x, deg_to_rad(-85), deg_to_rad(85))
		camera.rotation.y -= recovered.y
		recoil_offset -= recovered
	if time_since_shot > 0.45:
		burst_shot = 0

func _clear_handling() -> void:
	if is_instance_valid(camera):
		camera.rotation.x = clampf(camera.rotation.x - recoil_offset.x, deg_to_rad(-85), deg_to_rad(85))
		camera.rotation.y -= recoil_offset.y
	recoil_offset = Vector2.ZERO
	spread_bloom = 0
	burst_shot = 0
	time_since_shot = 10
	aim_blend = 0



func scope_style() -> String:
	if armory.selected_category == 4:
		return ["mil_dot", "mil_tree", "mil_dot", "mil_dot", "pso", "fine_cross", "mil_tree", "mil_tree", "duplex", "pu_post"][armory.selected_index]
	if armory.selected_category == 0:
		return "aug_ring" if armory.selected_index == 4 else "g36"
	return "pgo"

func scope_fov() -> float:
	return rad_to_deg(2.0 * atan(tan(deg_to_rad(75.0 / 2.0)) / optic_magnification()))

func optic_magnification() -> float:
	if armory.selected_category == 4:
		return [8.0,8.0,10.0,8.0,4.0,6.0,8.0,8.0,6.0,3.5][armory.selected_index]
	if armory.selected_category == 0:
		return 1.5 if armory.selected_index == 4 else 3.0
	return 2.7

func optic_name() -> String:
	if armory.selected_category == 4:
		return ["Mil-dot variable optic", "Nightforce-style MIL-XT", "Fixed 10x mil-dot", "Mil-dot variable optic", "PSO-1", "Hensoldt-style 6x", "Nightforce-style MIL-XT", "Nightforce-style MIL-XT", "Kahles-style duplex", "PU"][armory.selected_index]
	if armory.selected_category == 0:
		return "AUG A1 integral optic" if armory.selected_index == 4 else "G36 integral optic"
	return "PGO-7 style" if armory.selected_index == 0 else "1P38 style"
func _melee_attack() -> void:
	melee_duration = 0.82 if armory.selected_index >= 6 else 0.62
	cooldown = melee_duration
	melee_elapsed = 0
	melee_impact_done = false
	melee_swing = 1
	shots_fired += 1

func _advance_melee(delta: float) -> void:
	if melee_elapsed < 0:
		return
	if armory.is_open or not player.controls_active or armory.selected_category != 5:
		melee_elapsed = -1
		melee_swing = 0
		return
	melee_elapsed += delta
	if not melee_impact_done and melee_elapsed >= melee_duration * 0.44:
		melee_impact_done = true
		_melee_impact()
	if melee_elapsed >= melee_duration:
		melee_elapsed = -1
		melee_swing = 0

func _melee_impact() -> void:
	var origin := camera.global_position
	var query := PhysicsRayQueryParameters3D.create(origin,origin - camera.global_basis.z * 2.2)
	query.exclude = [player.get_rid()]
	var hit := player.get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		_hit_target(hit.collider, [65,70,75,60,85,80,90,85,70,75][armory.selected_index])

func _update_melee_pose() -> void:
	var heavy: bool = armory.selected_index >= 6
	var rest_position := Vector3(0.30,-0.28,-0.70)
	var rest_rotation := Vector3(1.15,-0.12,-0.25)
	var wind_position := Vector3(0.42,-0.13,-0.58)
	var wind_rotation := Vector3(1.65,0.15,-0.7) if heavy else Vector3(1.3,0.25,-0.95)
	var strike_position := Vector3(-0.10,-0.27,-0.95)
	var strike_rotation := Vector3(0.15,-0.5,0.45) if heavy else Vector3(0.40,-0.4,1.15)
	var position: Vector3 = rest_position
	var rotation: Vector3 = rest_rotation
	if melee_elapsed >= 0:
		var phase: float = clampf(melee_elapsed / melee_duration,0,1)
		if phase < 0.24:
			var blend: float = smoothstep(0,0.24,phase)
			position = rest_position.lerp(wind_position,blend)
			rotation = rest_rotation.lerp(wind_rotation,blend)
		elif phase < 0.50:
			var blend: float = smoothstep(0.24,0.50,phase)
			position = wind_position.lerp(strike_position,blend)
			rotation = wind_rotation.lerp(strike_rotation,blend)
		else:
			var blend: float = smoothstep(0.50,1.0,phase)
			position = strike_position.lerp(rest_position,blend)
			rotation = strike_rotation.lerp(rest_rotation,blend)
	armory.weapon.position = position
	armory.weapon.rotation = rotation



func _auto_reload() -> void:
	if armory.selected_category < 0 or armory.selected_category == 5:
		return
	if armory.is_open or not player.controls_active or player.get_meta("explosive_equipped",false):
		return
	if reload_remaining > 0:
		return
	var state := ammo_state()
	if state.loaded == 0 and state.reserve > 0:
		start_reload()

func reset_ammo() -> void:
	cancel_input()
	cooldown = 0
	# Unvisited weapons initialize full; clearing cached states refills both slots and all previously used guns.
	ammo_states.clear()
	if armory.selected_category >= 0:
		ammo_state()
	_update_ammo_hud()
func _clear_launcher_sight() -> void:
	# Reserve the complete ladder sight rectangle, not just its center ray.
	# Project each transformed mesh bound so wide tubes and recoil stay below it.
	var slope: float = 73.0 / maxf(1.0,camera.get_viewport().get_visible_rect().size.y * .5) * tan(deg_to_rad(camera.fov*.5))
	var lower_by := 0.0
	for component in armory.weapon.get_children():
		if not component is MeshInstance3D or not component.visible:
			continue
		var bounds: AABB = component.mesh.get_aabb()
		for corner in range(8):
			var point: Vector3 = camera.to_local(component.to_global(bounds.get_endpoint(corner)))
			if point.z < -.02:
				lower_by = maxf(lower_by,point.y + (-point.z)*slope)
	armory.weapon.position.y -= lower_by