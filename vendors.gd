extends CanvasLayer

const ITEMS := ["Grenade", "C4", "Landmine"]
const PRICES := [100, 200, 150]
var carry_limit: int = 2
var credits: int = 1500
var inventory: Array[int] = [0, 0, 0]
var vendors: Array[StaticBody3D] = []
var nearest: StaticBody3D
var is_open := false
var player: CharacterBody3D
var armory: CanvasLayer
var prompt: Label
var wallet: Label
var overlay: ColorRect
var title: Label
var dialogue: Label
var status: Label
var buttons: Array[Button] = []

func _ready() -> void:
	credits = clampi(get_node("/root/GameSettings").match_rules.money,0,10000)
	carry_limit = clampi(int(get_node("/root/GameSettings").match_rules.get("explosive_limit",2)),0,20)
	layer = 20
	player = get_parent().get_node("Player")
	armory = get_parent().get_node("Armory")
	_make_vendor("Morgan", Vector3(0, 3.625, -15), Color("479fa6"))
	_make_vendor("Casey", Vector3(0, 3.625, 15), Color("d68a48"))
	prompt = Label.new()
	add_child(prompt)
	prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	prompt.position = Vector2(-260, -155)
	prompt.size = Vector2(520,40)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 22)
	wallet = Label.new()
	add_child(wallet)
	wallet.position = Vector2(24,175)
	wallet.add_theme_font_size_override("font_size",18)
	wallet.add_theme_color_override("font_shadow_color",Color.BLACK)
	wallet.add_theme_constant_override("shadow_offset_x",2)
	wallet.add_theme_constant_override("shadow_offset_y",2)
	overlay = ColorRect.new()
	add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.025,0.04,0.07,0.97)
	var center := CenterContainer.new()
	overlay.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(620,0)
	column.add_theme_constant_override("separation",18)
	center.add_child(column)
	title = Label.new()
	title.add_theme_font_size_override("font_size",30)
	column.add_child(title)
	dialogue = Label.new()
	column.add_child(dialogue)
	for i in range(3):
		var button := Button.new()
		button.custom_minimum_size.y = 65
		button.pressed.connect(buy.bind(i))
		column.add_child(button)
		buttons.append(button)
	status = Label.new()
	column.add_child(status)
	var close := Button.new()
	close.text = "Goodbye  [E / Esc]"
	close.pressed.connect(close_shop)
	column.add_child(close)
	overlay.hide()
	_refresh()

func _make_vendor(vendor_name: String, point: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.name = vendor_name
	body.add_to_group("vendors")
	get_parent().add_child(body)
	body.position = point
	vendors.append(body)
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 1.9
	shape.shape = capsule
	shape.position.y = 0.95
	body.add_child(shape)
	_part(body,Vector3(0.65,0.7,0.35),Vector3(0,1.1,0),color)
	_part(body,Vector3(0.42,0.43,0.42),Vector3(0,1.68,0),Color("dfb28a"))
	_part(body,Vector3(0.48,0.13,0.48),Vector3(0,1.93,0),color.darkened(0.4))
	for side in [-1,1]:
		_part(body,Vector3(0.22,0.72,0.28),Vector3(side*0.2,0.4,0),Color("303e52"))
		_part(body,Vector3(0.19,0.65,0.25),Vector3(side*0.46,1.05,0),color)
		_part(body,Vector3(0.07,0.06,0.02),Vector3(side*0.1,1.73,0.22),Color("29323c"))
	preload("res://model_details.gd").character(body,false)
	var label := Label3D.new()
	label.text = vendor_name + "\nEXPLOSIVES SHOP"
	label.position.y = 2.4
	label.font_size = 32
	label.pixel_size = 0.008
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	body.add_child(label)

func _part(body: Node3D, dimensions: Vector3, point: Vector3, color: Color, kind: String = "box", angles: Vector3 = Vector3.ZERO) -> void:
	var mesh := MeshInstance3D.new()
	mesh.mesh = preload("res://weapon_mesh.gd").mesh(dimensions,kind)
	mesh.rotation = angles
	mesh.position = point
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	mesh.material_override = material
	body.add_child(mesh)

func _process(_delta: float) -> void:
	nearest = null
	var best: float = 3.0
	if player.controls_active and not armory.is_open:
		for vendor in vendors:
			var distance: float = player.global_position.distance_to(vendor.global_position + Vector3.UP)
			if distance < best:
				var query := PhysicsRayQueryParameters3D.create(player.camera.global_position,vendor.global_position + Vector3.UP * 1.4)
				query.exclude = [player.get_rid()]
				var hit := player.get_world_3d().direct_space_state.intersect_ray(query)
				if not hit.is_empty() and hit.collider == vendor:
					best = distance
					nearest = vendor
	prompt.visible = nearest != null and not is_open
	if nearest != null:
		prompt.text = "E  Talk to " + str(nearest.name)
	wallet.visible = not is_open and not armory.is_open

func _input(event: InputEvent) -> void:
	if get_node("/root/GameSettings").mode() == 1:
		return
	if player.get_meta("dead", false):
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if is_open and (event.is_action("interact") or event.physical_keycode == KEY_ESCAPE):
			close_shop()
			get_viewport().set_input_as_handled()
		elif not is_open and event.is_action("interact") and nearest != null and player.controls_active and not armory.is_open:
			open_shop(nearest)
			get_viewport().set_input_as_handled()
	elif is_open and (event is InputEventMouseButton or event is InputEventMouseMotion):
		# GUI receives clicks; the full-screen panel blocks gameplay input.
		pass

func open_shop(vendor: StaticBody3D) -> void:
	is_open = true
	title.text = str(vendor.name) + " / Supply shop"
	dialogue.text = '"Need supplies? Take a look. What can I get you?"\nStarter credits and purchases last for this play session.'
	status.text = "Choose an item to buy. Carry limit: %d explosives total." % carry_limit
	player.set_meta("shopping",true)
	player.controls_active = false
	player.set_physics_process(false)
	armory.get_node("Combat").cancel_input()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	overlay.show()
	_refresh()
	buttons[0].grab_focus()

func close_shop() -> void:
	is_open = false
	overlay.hide()
	player.set_meta("shopping",false)
	player.controls_active = true
	player.set_physics_process(true)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func buy(index: int) -> void:
	if not is_open or index < 0 or index >= ITEMS.size():
		return
	if credits < PRICES[index] or carried_count() >= carry_limit:
		return
	credits -= PRICES[index]
	inventory[index] += 1
	status.text = '"Good choice. Added one %s to your supplies."' % ITEMS[index]
	_refresh()

func _refresh() -> void:
	wallet.text = "Credits: %d\nGrenades: %d   C4: %d   Landmines: %d" % [credits,inventory[0],inventory[1],inventory[2]]
	for i in range(buttons.size()):
		buttons[i].text = "%s  /  %d credits  /  Owned %d / Total limit %d" % [ITEMS[i],PRICES[i],inventory[i],carry_limit]
		buttons[i].disabled = credits < PRICES[i] or carried_count() >= carry_limit
	if is_open:
		title.text = title.text.split(" / ")[0] + " / Supply shop / %d credits" % credits


func carried_count() -> int:
	return inventory[0] + inventory[1] + inventory[2]

func award_kill() -> void:
	credits += 100
	_refresh()