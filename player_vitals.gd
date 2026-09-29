extends CanvasLayer
const MAX_HEALTH := 100
const MAX_SHIELD := 50
var regeneration = preload("res://regeneration.gd").new()
var health: int = MAX_HEALTH
var shield: int = MAX_SHIELD
var respawn_remaining: float = 0
var player: CharacterBody3D
var health_bar: ProgressBar
var shield_bar: ProgressBar
var readout: Label
var health_text: Label
var shield_text: Label
var flash: ColorRect

func _ready() -> void:
	layer = 30
	player = get_parent().get_node("Player")
	var panel := VBoxContainer.new()
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	panel.offset_left = -170
	panel.offset_right = 170
	panel.offset_top = 16
	panel.offset_bottom = 90
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	readout = Label.new()
	readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	readout.add_theme_font_size_override("font_size",18)
	readout.add_theme_color_override("font_shadow_color",Color.BLACK)
	readout.add_theme_constant_override("shadow_offset_x",2)
	readout.add_theme_constant_override("shadow_offset_y",2)
	panel.add_child(readout)
	shield_bar = _bar(panel,MAX_SHIELD,Color("50bde6"),26)
	health_bar = _bar(panel,MAX_HEALTH,Color("79d67d"),26)
	shield_text = _bar_text(shield_bar)
	health_text = _bar_text(health_bar)
	flash = ColorRect.new()
	add_child(flash)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.color = Color(0.8,0.04,0.02,0)
	_refresh()

func _bar(parent: Control, maximum: int, color: Color, height: float) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.max_value = maximum
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(340,height)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("16232c")
	bg.set_corner_radius_all(3)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("background",bg)
	bar.add_theme_stylebox_override("fill",fill)
	parent.add_child(bar)
	return bar

func blast_damage(point: Vector3, amount: int) -> void:
	if health <= 0:
		return
	var center: Vector3 = player.global_position
	var distance: float = center.distance_to(point)
	if distance >= 4.0:
		return
	var toward: Vector3 = (center-point).normalized()
	var query := PhysicsRayQueryParameters3D.create(point+toward*0.04,center)
	query.exclude = [player.get_rid()]
	if not player.get_world_3d().direct_space_state.intersect_ray(query).is_empty():
		return
	var multiplier: float = 1.0 if distance <= 1 else lerpf(1.0,0.25,(distance-1)/3)
	take_damage(maxi(1,roundi(amount*multiplier)))

func take_damage(amount: int, attacker_id: int = 0) -> void:
	if attacker_id != 0 and not get_node("/root/GameSettings").hostile(attacker_id,0):
		return
	if not get_parent().get_meta("round_active",true):
		return
	if health <= 0 or amount <= 0:
		return
	regeneration.reset()
	var absorbed: int = mini(shield,amount)
	shield -= absorbed
	health = maxi(0,health-(amount-absorbed))
	flash.color.a = 0.24
	if health == 0:
		get_parent().get_node("Scoreboard").record_death(0,attacker_id)
		var shop = get_parent().get_node("Vendors")
		if shop.is_open:
			shop.close_shop()
		var armory = get_parent().get_node("Armory")
		if armory.is_open:
			armory.set_open(false)
		armory.get_node("Combat").cancel_input()
		get_parent().get_node("Explosives").stow()
		player.set_meta("dead",true)
		player.controls_active = false
		player.velocity = Vector3.ZERO
		respawn_remaining = 2.0
	_refresh()

func _process(delta: float) -> void:
	visible = not get_parent().get_node("Armory").is_open and not get_parent().get_node("Vendors").is_open
	regeneration.advance(self,delta)
	_refresh()
	flash.color.a = move_toward(flash.color.a,0,delta*0.6)
	if respawn_remaining > 0:
		respawn_remaining = maxf(0,respawn_remaining-delta)
		if respawn_remaining == 0:
			respawn()
		_refresh()

func respawn(randomize_position: bool = true) -> void:
	regeneration.reset()
	get_parent().get_node("Armory/Combat").reset_ammo()
	health = MAX_HEALTH
	shield = MAX_SHIELD
	respawn_remaining = 0
	if randomize_position:
		player.global_position = get_parent().get_node("Enemies").pick_spawn(player)
	player.velocity = Vector3.ZERO
	player.rotation = Vector3.ZERO
	player.camera.rotation = Vector3.ZERO
	player.camera.position.y = 0.65
	player.set_meta("dead",false)
	player.controls_active = true
	player.set_physics_process(true)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_refresh()

func _refresh() -> void:
	health_bar.value = health
	shield_bar.value = shield
	health_text.text = "HEALTH %d / 100" % health
	shield_text.text = "SHIELD %d / 50" % shield
	readout.visible = health == 0
	if health == 0:
		readout.text = "ELIMINATED / Respawn in %.1fs" % respawn_remaining

func _bar_text(bar: ProgressBar) -> Label:
	var label := Label.new()
	bar.add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size",16)
	label.add_theme_color_override("font_color",Color.WHITE)
	label.add_theme_color_override("font_outline_color",Color("101a20"))
	label.add_theme_constant_override("outline_size",4)
	return label