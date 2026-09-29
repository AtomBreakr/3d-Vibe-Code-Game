extends Node

var shop: CanvasLayer
var player: CharacterBody3D
var armory: CanvasLayer
var combat: Node
var selected: int = -1
var held: Node3D
var placed: Array[Dictionary] = []
var hint: Label
var message: String = ""
var message_time: float = 0

func _ready() -> void:
	shop = get_parent().get_node("Vendors")
	player = get_parent().get_node("Player")
	armory = get_parent().get_node("Armory")
	combat = armory.get_node("Combat")
	var layer := CanvasLayer.new()
	layer.layer = 6
	add_child(layer)
	hint = Label.new()
	layer.add_child(hint)
	hint.position = Vector2(24,235)
	hint.add_theme_font_size_override("font_size",18)
	hint.add_theme_color_override("font_shadow_color",Color.BLACK)
	hint.add_theme_constant_override("shadow_offset_x",2)
	hint.add_theme_constant_override("shadow_offset_y",2)

func _input(event: InputEvent) -> void:
	if shop.is_open or armory.is_open or not player.controls_active:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.is_action("explosive"):
			press_g()
			get_viewport().set_input_as_handled()
		elif (event.is_action("primary") or event.is_action("secondary") or event.is_action("armory")):
			stow()
	if selected >= 0 and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				use_selected()
			get_viewport().set_input_as_handled()
		elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			stow()

func press_g() -> void:
	if get_node("/root/GameSettings").mode() == 1:
		return
	var detonated := false
	for i in range(placed.size()-1,-1,-1):
		if placed[i].kind == 1:
			_detonate(i)
			detonated = true
	if detonated:
		stow()
		return
	for offset in range(1,4):
		var index: int = (selected + offset) % 3
		if shop.inventory[index] > 0:
			equip(index)
			return
	message = "No explosives. Visit an upstairs vendor."
	message_time = 3
	stow()

func equip(index: int) -> void:
	stow()
	selected = index
	player.set_meta("explosive_equipped",true)
	combat.cancel_input()
	held = _model(index)
	player.camera.add_child(held)
	held.position = Vector3(0.25,-0.22,-0.6)
	held.rotation = Vector3(0.1,-0.25,0.12)

func stow() -> void:
	selected = -1
	player.set_meta("explosive_equipped",false)
	if is_instance_valid(held):
		held.queue_free()
	held = null

func _model(kind: int) -> Node3D:
	var model := Node3D.new()
	var dimensions: Vector3 = [Vector3(0.12,0.18,0.12),Vector3(0.24,0.12,0.16),Vector3(0.25,0.06,0.25)][kind]
	shop._part(model,dimensions,Vector3.ZERO,Color("536447"))
	shop._part(model,Vector3(0.04,0.025,0.06),Vector3(0,dimensions.y/2+0.01,0),Color("dc7351"))
	if kind == 1:
		shop._part(model,Vector3(0.035,0.13,0.17),Vector3(-0.07,0,0),Color("30383d"))
		shop._part(model,Vector3(0.035,0.13,0.17),Vector3(0.07,0,0),Color("30383d"))
	for side in [-1,1]:
		for i in range(3):
			shop._part(model,Vector3(0.018,dimensions.y*0.8,0.014),Vector3(side*(dimensions.x/2+0.006),0,-dimensions.z*0.3+i*dimensions.z*0.3),Color("87916a"))
	shop._part(model,Vector3(dimensions.x*0.5,0.009,dimensions.z*0.3),Vector3(0,dimensions.y/2+0.008,0.035),Color("c9bb78"))
	if kind == 1:
		shop._part(model,Vector3(0.07,0.02,0.045),Vector3(0,0.085,0),Color("363d44"))
		shop._part(model,Vector3(0.045,0.006,0.026),Vector3(0,0.098,0),Color("8dd1b1"))
	elif kind == 0:
		shop._part(model,Vector3(0.026,0.16,0.025),Vector3(0.045,0.055,0),Color("b2b6a4"))
	return model

func use_selected() -> void:
	if not get_parent().get_meta("round_active",true):
		return
	if selected < 0 or shop.inventory[selected] <= 0:
		return
	var kind := selected
	var origin: Vector3 = player.camera.global_position
	var direction: Vector3 = -player.camera.global_basis.z
	var query := PhysicsRayQueryParameters3D.create(origin,origin + direction * 3.5)
	query.exclude = [player.get_rid()]
	var hit := player.get_world_3d().direct_space_state.intersect_ray(query)
	if kind != 0 and (hit.is_empty() or (kind == 2 and hit.normal.y < 0.75)):
		message = "Aim at nearby ground to place a landmine." if kind == 2 else "Aim at a nearby surface to place C4."
		message_time = 3
		return
	var model := _model(kind)
	get_parent().add_child(model)
	var velocity := Vector3.ZERO
	if kind == 0:
		model.global_position = origin
		velocity = direction * 12 + Vector3.UP * 3
	else:
		model.global_position = hit.position + hit.normal * 0.10
		var up: Vector3 = hit.normal
		var tangent: Vector3 = Vector3.RIGHT if absf(up.dot(Vector3.RIGHT)) < 0.9 else Vector3.FORWARD
		var axis: Vector3 = tangent.cross(up).normalized()
		model.global_basis = Basis(up.cross(axis).normalized(),up,axis)
	placed.append({"node":model,"kind":kind,"velocity":velocity,"age":0.0})
	shop.inventory[kind] -= 1
	shop._refresh()
	stow()

func _physics_process(delta: float) -> void:
	for i in range(placed.size()-1,-1,-1):
		var item: Dictionary = placed[i]
		item.age += delta
		if item.kind == 0:
			item.velocity += Vector3.DOWN * 18 * delta
			var start: Vector3 = item.node.global_position
			var end: Vector3 = start + item.velocity * delta
			var query := PhysicsRayQueryParameters3D.create(start,end)
			query.exclude = [player.get_rid()]
			var hit := player.get_world_3d().direct_space_state.intersect_ray(query)
			if hit.is_empty():
				item.node.global_position = end
			else:
				item.node.global_position = hit.position + hit.normal * 0.08
				item.velocity = item.velocity.bounce(hit.normal) * 0.45
			if item.age >= 2.5:
				_detonate(i)
		elif item.kind == 2 and item.age > 1.0:
			# Practice targets stand in for enemies; owner and friendly vendors never trigger mines.
			for target in (get_tree().get_nodes_in_group("practice_targets") + get_tree().get_nodes_in_group("enemies")):
				if (not target.is_in_group("enemies") or get_node("/root/GameSettings").hostile(0,target.target_number)) and target.global_position.distance_to(item.node.global_position) < 2.2:
					var query := PhysicsRayQueryParameters3D.create(item.node.global_position,target.global_position)
					query.exclude = [player.get_rid()]
					var hit := player.get_world_3d().direct_space_state.intersect_ray(query)
					if hit.is_empty() or hit.collider == target:
						_detonate(i)
						break

func _detonate(index: int) -> void:
	var item: Dictionary = placed[index]
	combat.explode(item.node.global_position,150 if item.kind == 0 else 200)
	item.node.queue_free()
	placed.remove_at(index)

func _process(delta: float) -> void:
	if selected >= 0 and (shop.is_open or armory.is_open or not player.controls_active):
		stow()
	message_time = maxf(0,message_time-delta)
	hint.visible = not shop.is_open and not armory.is_open
	var remote_count := 0
	for item in placed:
		if item.kind == 1:
			remote_count += 1
	hint.text = "G  Equip / cycle explosives  |  Carrying %d / 2" % shop.carried_count()
	if selected >= 0:
		hint.text = shop.ITEMS[selected] + "  |  Left click: throw / place  |  1 / 2: weapon"
	if remote_count > 0:
		hint.text += "\nG  Detonate placed C4 (%d)" % remote_count
	if message_time > 0:
		hint.text += "\n" + message
