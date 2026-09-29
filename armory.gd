extends CanvasLayer

const CATEGORIES := ["Assault Rifles", "Pistols", "Machine Guns", "Rocket Launchers", "Sniper Rifles", "Melee"]
const Catalog = preload("res://weapon_catalog.gd")
const COLORS := ["eea55b", "60d5c7", "d2c174", "71aff4", "f07882", "ad8bf0", "8fd077", "e9ce87", "86cadc", "db96ca"]
var player: CharacterBody3D
var overlay: ColorRect
var grid: GridContainer
var heading: Label
var status: Label
var tabs: Array[Button] = []
var active_category: int = 0
var selected_category: int = -1
var selected_index: int = -1
var weapon: Node3D
var is_open: bool = false
var loadout: Array = [[0,0], [1,1]]
var active_slot: int = 0
var editing_slot: int = 0
var slot_buttons: Array[Button] = []
const SLOT_CATEGORIES := [[0,4,2], [1,3,5]]

func _ready() -> void:
	layer = 10
	player = get_parent().get_node("Player")
	_build_ui()
	_refresh_slots()
	_show_category(0)
	overlay.hide()
	var combat := Node.new()
	combat.name = "Combat"
	combat.set_script(preload("res://combat.gd"))
	add_child(combat)
	switch_slot(0)

func _input(event: InputEvent) -> void:
	if get_node("/root/GameSettings").mode() == 1:
		return
	if player.get_meta("dead", false):
		return
	if player.has_meta("shopping") and player.get_meta("shopping"):
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.is_action("armory") or (event.keycode == KEY_ESCAPE and is_open):
			set_open(not is_open)
			get_viewport().set_input_as_handled()
			return
	if not is_open and player.controls_active:
		if event is InputEventKey and event.pressed and not event.echo:
			if (event.is_action("primary") or event.is_action("secondary")):
				switch_slot(0 if event.is_action("primary") else 1)
				get_viewport().set_input_as_handled()
		if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			switch_slot(1 - active_slot)
			get_viewport().set_input_as_handled()

func set_open(value: bool) -> void:
	if value and get_node("/root/GameSettings").mode() == 1:
		return
	is_open = value
	if value and has_node("Combat"):
		get_node("Combat").cancel_input()
	overlay.visible = value
	player.controls_active = not value
	player.set_physics_process(not value)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if value else Input.MOUSE_MODE_CAPTURED
	get_parent().get_node("HUD/Crosshair").visible = not value
	if value:
		_show_category(active_category)
		tabs[active_category].grab_focus()

func style(color: Color, border: Color) -> StyleBoxFlat:
	var result := StyleBoxFlat.new()
	result.bg_color = color
	result.border_color = border
	result.set_border_width_all(2)
	result.set_corner_radius_all(6)
	result.content_margin_left = 16
	result.content_margin_right = 16
	result.content_margin_top = 12
	result.content_margin_bottom = 12
	return result

func _build_ui() -> void:
	overlay = ColorRect.new()
	overlay.color = Color(0.025, 0.045, 0.08, 0.96)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 24)
	overlay.add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 18)
	margin.add_child(layout)
	var top := HBoxContainer.new()
	layout.add_child(top)
	var title := Label.new()
	title.text = "BLOCKTOWN / ARMORY"
	title.add_theme_font_size_override("font_size", 28)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	var close := Button.new()
	close.text = "BACK TO MAP   [B / Esc]"
	close.pressed.connect(func(): set_open(false))
	top.add_child(close)
	var hint := Label.new()
	hint.text = "Choose a slot, then a weapon.   /   In-game: 1 Primary • 2 Secondary • Mouse wheel to switch"
	hint.add_theme_color_override("font_color", Color("96b3c9"))
	layout.add_child(hint)
	var slots := HBoxContainer.new()
	slots.add_theme_constant_override("separation", 12)
	layout.add_child(slots)
	for slot in range(2):
		var button := Button.new()
		button.toggle_mode = true
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 50
		button.add_theme_stylebox_override("pressed", style(Color("246569"), Color("64e6ce")))
		button.pressed.connect(_edit_slot.bind(slot))
		slots.add_child(button)
		slot_buttons.append(button)
	_refresh_slots()
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 24)
	layout.add_child(body)
	var sidebar := VBoxContainer.new()
	sidebar.custom_minimum_size.x = 210
	sidebar.add_theme_constant_override("separation", 10)
	body.add_child(sidebar)
	for category in range(CATEGORIES.size()):
		var button := Button.new()
		button.text = CATEGORIES[category]
		button.custom_minimum_size.y = 60
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.toggle_mode = true
		button.add_theme_stylebox_override("normal", style(Color("152638"), Color("284056")))
		button.add_theme_stylebox_override("pressed", style(Color("246569"), Color("64e6ce")))
		button.pressed.connect(_show_category.bind(category))
		sidebar.add_child(button)
		tabs.append(button)
	var main := VBoxContainer.new()
	main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main.add_theme_constant_override("separation", 12)
	body.add_child(main)
	heading = Label.new()
	heading.add_theme_font_size_override("font_size", 24)
	main.add_child(heading)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main.add_child(scroll)
	grid = GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(grid)
	status = Label.new()
	status.text = "EQUIPPED: NONE    /    50 voxel weapons available"
	status.add_theme_color_override("font_color", Color("64e6ce"))
	layout.add_child(status)

func _show_category(category: int) -> void:
	if category not in SLOT_CATEGORIES[editing_slot]:
		category = SLOT_CATEGORIES[editing_slot][0]
	active_category = category
	heading.text = CATEGORIES[category].to_upper() + "   /   10 WEAPONS"
	for i in range(tabs.size()):
		tabs[i].set_pressed_no_signal(i == category)
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()
	for index in range(10):
		var button := Button.new()
		var equipped: bool = category == selected_category and index == selected_index
		button.text = "%02d   %s\n%s" % [index + 1, Catalog.PROFILES[category][index][0], "IN LOADOUT" if [category,index] in loadout else ("SET PRIMARY" if editing_slot == 0 else "SET SECONDARY")]
		button.icon = make_icon(category, index)
		button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.expand_icon = false
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(260, 100)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 16)
		button.add_theme_stylebox_override("normal", style(Color("192d41"), Color(COLORS[index]) if equipped else Color("30465b")))
		button.add_theme_stylebox_override("hover", style(Color("29465c"), Color(COLORS[index])))
		button.pressed.connect(assign_slot.bind(category, index))
		grid.add_child(button)

func make_icon(category: int, index: int) -> ImageTexture:
	var shapes: Array = Catalog.geometry(category, index)
	var min_z: float = 100
	var max_z: float = -100
	for shape in shapes:
		min_z = minf(min_z, shape[1].z - shape[0].z / 2)
		max_z = maxf(max_z, shape[1].z + shape[0].z / 2)
	var scale_factor: float = minf(76.0 / (max_z - min_z), 65.0)
	var img := Image.create(88, 48, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	for shape in shapes:
		var size: Vector3 = shape[0]
		var location: Vector3 = shape[1]
		var x: int = int(6 + (max_z - location.z - size.z / 2) * scale_factor)
		var y: int = int(23 - (location.y + size.y / 2) * scale_factor)
		var rect := Rect2i(x, y, maxi(1, int(size.z * scale_factor)), maxi(1, int(size.y * scale_factor)))
		rect = rect.intersection(Rect2i(0, 0, 88, 48))
		img.fill_rect(rect, shape[2].lightened(0.18))
	return ImageTexture.create_from_image(img)
func equip(category: int, index: int) -> void:
	selected_category = category
	selected_index = index
	if is_instance_valid(weapon):
		weapon.get_parent().remove_child(weapon)
		weapon.queue_free()
	weapon = Node3D.new()
	weapon.name = "HeldWeapon"
	player.camera.add_child(weapon)
	weapon.position = Vector3(0.27, -0.23, -0.68)
	weapon.scale = Vector3.ONE * (0.65 if category in [2, 3, 4] else 0.85)
	for shape in Catalog.geometry(category, index):
		part(shape[0], shape[1], shape[2])
	if category == 5:
		part(Vector3(0.105,0.10,0.13),Vector3(0,-0.035,0.10),Color("dca976"))
		for finger in range(3):
			part(Vector3(0.115,0.045,0.022),Vector3(0,0.012,0.055+finger*0.035),Color("c59064"))
		part(Vector3(0.12,0.13,0.25),Vector3(0,-0.025,0.29),Color("3c6978"))
	else:
		part(Vector3(0.10, 0.10, 0.12), Vector3(0, -0.16, 0.10), Color("dca976"))
		part(Vector3(0.12, 0.13, 0.23), Vector3(0.02, -0.21, 0.22), Color("3c6978"))
	if category != 5:
		var muzzle := Marker3D.new()
		muzzle.name = "Muzzle"
		muzzle.position = Catalog.muzzle_position(category,index)
		weapon.add_child(muzzle)
	if has_node("Combat"):
		get_node("Combat").cancel_input()
	status.text = "EQUIPPED: " + Catalog.PROFILES[category][index][0].to_upper() + "    /    " + CATEGORIES[category]
	set_open(false)

func part(size: Vector3, location: Vector3, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.position = location
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material_override = material
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	weapon.add_child(mesh)



func _refresh_slots() -> void:
	for category in range(tabs.size()):
		tabs[category].visible = category in SLOT_CATEGORIES[editing_slot]
	if not tabs.is_empty():
		for category in SLOT_CATEGORIES[editing_slot]:
			tabs[category].get_parent().move_child(tabs[category], -1)
	for slot in range(slot_buttons.size()):
		var entry: Array = loadout[slot]
		slot_buttons[slot].text = ("1  PRIMARY" if slot == 0 else "2  SECONDARY") + "  /  " + Catalog.PROFILES[entry[0]][entry[1]][0]
		slot_buttons[slot].set_pressed_no_signal(slot == editing_slot)

func _edit_slot(slot: int) -> void:
	editing_slot = slot
	_refresh_slots()
	_show_category(active_category)

func assign_slot(category: int, index: int) -> void:
	if category not in SLOT_CATEGORIES[editing_slot]:
		return
	var selection: Array = [category,index]
	var other: int = 1 - editing_slot
	if loadout[other] == selection:
		loadout[other] = loadout[editing_slot]
	loadout[editing_slot] = selection
	# Rebuild the active model while keeping the armory open for the second choice.
	equip(loadout[active_slot][0], loadout[active_slot][1])
	set_open(true)
	_refresh_slots()
	status.text = "LOADOUT SAVED   /   B or Esc to return   /   Ammo is preserved"

func switch_slot(slot: int) -> void:
	if slot < 0 or slot > 1:
		return
	if active_slot == slot and is_instance_valid(weapon) and selected_category == loadout[slot][0] and selected_index == loadout[slot][1]:
		return
	active_slot = slot
	equip(loadout[slot][0], loadout[slot][1])
	_refresh_slots()


