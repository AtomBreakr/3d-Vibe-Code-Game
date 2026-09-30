extends CanvasLayer
var in_game := false
var settings: Node
var column: VBoxContainer
var status: Label
var waiting: String = ""
var bind_button: Button
var page := "home"
var margin: MarginContainer
var artwork: TextureRect
var backdrop: Texture2D
var scroll: ScrollContainer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	settings = get_node("/root/GameSettings")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var background := Control.new()
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# A clean render of the actual map keeps the menu in the game's visual style.
	backdrop = preload("res://menu_backdrop.png")
	artwork = TextureRect.new()
	background.add_child(artwork)
	artwork.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	artwork.texture = backdrop
	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shade := TextureRect.new()
	background.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0,0.45,1])
	gradient.colors = PackedColorArray([Color(0.025,0.055,0.075,0.98),Color(0.025,0.055,0.075,0.89),Color(0.025,0.055,0.075,0.18)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2.ZERO
	texture.fill_to = Vector2.RIGHT
	shade.texture = texture
	var stripe := ColorRect.new()
	background.add_child(stripe)
	stripe.color = Color("f3bd61")
	stripe.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	stripe.offset_bottom = 5
	margin = MarginContainer.new()
	background.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.anchor_right = 0.57
	for edge in ["left","right"]:
		margin.add_theme_constant_override("margin_"+edge,48 if edge == "left" else 24)
	margin.add_theme_constant_override("margin_top",65)
	margin.add_theme_constant_override("margin_bottom",65)
	scroll = ScrollContainer.new()
	margin.add_child(scroll)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation",16)
	scroll.add_child(column)
	var footer := Label.new()
	background.add_child(footer)
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_left = 48
	footer.offset_top = -36
	footer.text = "BLOCKTOWN     /     LOCAL PLAY"
	footer.add_theme_font_size_override("font_size",13)
	footer.modulate = Color("adc8cb")
	home()

func clear(title: String) -> void:
	update_backdrop()
	waiting = ""
	scroll.scroll_vertical = 0
	for child in column.get_children():
		column.remove_child(child)
		child.queue_free()
	var heading := Label.new()
	heading.text = title
	heading.add_theme_font_size_override("font_size",44)
	heading.add_theme_color_override("font_color",Color("fff0d4"))
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(heading)

func text(value: String) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color",Color("b7cbd0"))
	label.add_theme_font_size_override("font_size",18)
	column.add_child(label)
	return label

func button(title: String, callback: Callable) -> Button:
	var item := Button.new()
	item.text = title
	item.custom_minimum_size.y = 52
	item.alignment = HORIZONTAL_ALIGNMENT_LEFT
	item.add_theme_font_size_override("font_size",20)
	item.add_theme_color_override("font_color",Color("eaf0e7"))
	item.add_theme_color_override("font_hover_color",Color("17252b"))
	item.add_theme_color_override("font_pressed_color",Color("17252b"))
	for state in ["normal","hover","pressed","focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("edbb68") if state in ["hover","pressed"] else Color(0.08,0.15,0.19,0.92)
		style.border_color = Color("f3bd61") if state != "normal" else Color("436369")
		style.border_width_left = 4
		style.content_margin_left = 20
		style.content_margin_right = 16
		style.content_margin_top = 12
		style.content_margin_bottom = 12
		if state == "focus":
			style.bg_color = Color.TRANSPARENT
			style.set_border_width_all(2)
		item.add_theme_stylebox_override(state,style)
	item.pressed.connect(callback)
	column.add_child(item)
	return item

func home() -> void:
	page = "home"
	clear("BLOCKTOWN / PAUSED" if in_game else "BLOCKTOWN")
	text("LOCK IN. LOAD UP.")
	var space := Control.new()
	space.custom_minimum_size.y = 30
	column.add_child(space)
	if in_game:
		button("Resume",resume)
	else:
		button("01   PLAY",levels)
	button("02   SETTINGS",options)
	if in_game:
		button("Return to Main Menu",return_to_menu)
	button("03   QUIT GAME",func(): get_tree().quit())

func levels() -> void:
	page = "levels"
	clear("SELECT LEVEL")
	var descriptions = ["Suburban houses and backyard firefights.","Grass blocks, oak trees and a timber village.","Tall apartments, city streets and a clock tower."]
	for i in range(3):
		var level_id: int = i
		button("%02d   %s" % [i+1,settings.LEVEL_NAMES[i]],func(): settings.selected_level=level_id; match_rules())
		text(descriptions[i])
	button("Back",home)
func options() -> void:
	page = "options"
	clear("SETTINGS")
	text("Sound & Controls")
	slider("Master volume",0,1,0.05,settings.volume,func(value): settings.volume=value; settings.apply())
	slider("Mouse sensitivity",0.2,3,0.1,settings.sensitivity,func(value): settings.sensitivity=value)
	text("Graphics")
	var full := CheckButton.new()
	full.text = "Fullscreen"
	full.button_pressed = settings.fullscreen
	full.toggled.connect(func(value): settings.fullscreen=value; settings.apply())
	column.add_child(full)
	var sync := CheckButton.new()
	sync.text = "VSync"
	sync.button_pressed = settings.vsync
	sync.toggled.connect(func(value): settings.vsync=value; settings.apply())
	column.add_child(sync)
	var quality := OptionButton.new()
	for item in ["Low / no shadows, no anti-aliasing","Medium / shadows, 2x anti-aliasing","High / shadows, 4x anti-aliasing"]:
		quality.add_item(item)
	quality.select(settings.quality)
	quality.item_selected.connect(func(value): settings.quality=value; settings.apply())
	column.add_child(quality)
	button("Keyboard bindings",bindings)
	status = text(settings.save_message)
	button("Save Settings",func(): settings.save(); status.text=settings.save_message)
	button("Back (save changes)",func(): settings.save(); home())

func slider(title: String, low: float, high: float, step: float, value: float, changed: Callable) -> void:
	var label := text("%s: %.2f" % [title,value])
	var control := HSlider.new()
	control.min_value = low
	control.max_value = high
	control.step = step
	control.value = value
	control.custom_minimum_size.y = 30
	control.value_changed.connect(func(number): label.text="%s: %.2f" % [title,number]; changed.call(number))
	column.add_child(control)

func bindings() -> void:
	page = "bindings"
	clear("KEYBOARD BINDINGS")
	text("Click an action, then press a key. Escape cancels binding.\nMouse: left fire / right aim / wheel switch. Escape opens the pause menu.")
	for action in settings.keys:
		var item := button(binding_text(action),func(): pass)
		item.pressed.connect(func(): waiting=action; bind_button=item; item.text="Press a key for " + action.replace("_"," "))
	status = text("")
	button("Restore default keys",func(): settings.keys=settings.DEFAULTS.duplicate(); settings.save(); bindings())
	button("Back (save changes)",func(): settings.save(); options())

func binding_text(action: String) -> String:
	return action.replace("_"," ").capitalize() + " : " + OS.get_keycode_string(settings.keys[action])

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if not waiting.is_empty():
		get_viewport().set_input_as_handled()
		if event.physical_keycode == KEY_ESCAPE:
			bind_button.text = binding_text(waiting)
			waiting = ""
			return
		for action in settings.keys:
			if action != waiting and settings.keys[action] == event.physical_keycode:
				status.text = "Already used by " + action.replace("_"," ") + ". Choose another key."
				return
		settings.keys[waiting] = event.physical_keycode
		settings.save()
		bind_button.text = binding_text(waiting)
		waiting = ""
		status.text = settings.save_message
	elif event.physical_keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		if page == "home" and in_game:
			resume()
		elif page != "home":
			settings.save()
			home()

func resume() -> void:
	get_tree().paused = false
	var scene = get_tree().current_scene
	scene.get_node("Player").controls_active = not scene.get_node("Player").get_meta("dead",false)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	queue_free()

func return_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://menu.tscn")
	queue_free()

func match_rules() -> void:
	page = "rules"
	clear("MATCH RULES")
	text(settings.LEVEL_NAMES[settings.selected_level].to_upper() + " / CUSTOM MATCH")
	rule_control("Starting credits","money",0,10000,100)
	rule_control("Maximum explosives carried","explosive_limit",0,20,1)
	text("Earn $100 per kill. Explosive limit is shared across all types; 0 disables purchases.")
	var mode_select := OptionButton.new()
	for mode_name in settings.MODE_NAMES:
		mode_select.add_item(mode_name)
	mode_select.select(settings.mode())
	mode_select.item_selected.connect(func(value): settings.match_rules.mode=value; match_rules())
	column.add_child(mode_select)
	if settings.mode() == 2:
		rule_control("Players per team (including you)","team_size",1,3,1)
		text("Equal teams. You are on Blue. Friendly fire is off.")
	else:
		rule_control("Enemy bots","bots",0,5,1)
	rule_control("Round length (minutes)","minutes",1,30,1)
	if settings.mode() == 1:
		text("Gun Game: 10 kills to win. Each kill upgrades your weapon.")
	else:
		rule_control("Team kills to win" if settings.mode() == 2 else "Kills to win","kills",1,100,1)
	text("Gun Game begins after a 5-second countdown." if settings.mode() == 1 else "Each round begins with 15 seconds to choose your loadout.\nStarting credits apply when you enter the level.")
	button("START MATCH",func():
		get_tree().paused = false
		get_tree().change_scene_to_file("res://main.tscn"))
	button("Reset rules",func(): settings.match_rules={"money":1500,"bots":4,"minutes":5,"kills":10,"mode":0,"team_size":3,"explosive_limit":2}; match_rules())
	button("Back to levels",levels)

func rule_control(title: String, key: String, minimum: int, maximum: int, increment: int) -> void:
	var row := HBoxContainer.new()
	column.add_child(row)
	var label := Label.new()
	label.text = title
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size",19)
	row.add_child(label)
	var input := SpinBox.new()
	input.min_value = minimum
	input.max_value = maximum
	input.step = increment
	input.value = settings.match_rules[key]
	input.custom_minimum_size = Vector2(140,42)
	input.value_changed.connect(func(value): settings.match_rules[key]=int(value))
	row.add_child(input)
func update_backdrop() -> void:
	var path = "res://menu_backdrop.png" if settings.selected_level == 0 else "res://map_background_%d.png" % settings.selected_level
	if ResourceLoader.exists(path):
		backdrop = load(path)
		artwork.texture = backdrop