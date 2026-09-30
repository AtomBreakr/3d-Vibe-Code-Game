extends Node

var selected_level: int = 0
const LEVEL_NAMES = ["Blocktown", "Voxel Valley", "Skyline District"]
const DEFAULTS := {"move_forward":KEY_W,"move_back":KEY_S,"move_left":KEY_A,"move_right":KEY_D,"jump":KEY_SPACE,"sprint":KEY_SHIFT,"crouch":KEY_CTRL,"reload":KEY_R,"armory":KEY_B,"interact":KEY_E,"explosive":KEY_G,"primary":KEY_1,"secondary":KEY_2,"scoreboard":KEY_TAB}
var keys: Dictionary = DEFAULTS.duplicate()
var match_rules := {"money":1500,"bots":4,"minutes":5,"kills":10,"mode":0,"team_size":3,"explosive_limit":2}
var volume := 0.8
var sensitivity := 1.0
var fullscreen := false
var vsync := true
var quality := 1
var save_message := ""
var save_path := "user://settings.cfg"
var pause_menu: Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var config := ConfigFile.new()
	if config.load(save_path) == OK:
		volume = clampf(config.get_value("options","volume",0.8),0,1)
		sensitivity = clampf(config.get_value("options","sensitivity",1.0),0.2,3)
		fullscreen = config.get_value("options","fullscreen",false)
		vsync = config.get_value("options","vsync",true)
		quality = clampi(config.get_value("options","quality",1),0,2)
		for action in DEFAULTS:
			keys[action] = config.get_value("keys",action,DEFAULTS[action])
	apply()

func apply() -> void:
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		InputMap.action_erase_events(action)
		var key := InputEventKey.new()
		key.physical_keycode = keys[action]
		InputMap.action_add_event(action,key)
	AudioServer.set_bus_volume_db(0,linear_to_db(maxf(volume,0.0001)))
	AudioServer.set_bus_mute(0,volume == 0)
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
	get_viewport().msaa_3d = [Viewport.MSAA_DISABLED,Viewport.MSAA_2X,Viewport.MSAA_4X][quality]
	apply_world()

func apply_world() -> void:
	var scene = get_tree().current_scene
	if scene != null and scene.has_node("Sun"):
		scene.get_node("Sun").shadow_enabled = quality > 0

func save() -> void:
	apply()
	var config := ConfigFile.new()
	for option in ["volume","sensitivity","fullscreen","vsync","quality"]:
		config.set_value("options",option,get(option))
	for action in keys:
		config.set_value("keys",action,keys[action])
	save_message = "Settings saved." if config.save(save_path) == OK else "Applied for this session; could not save settings."

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo or event.physical_keycode != KEY_ESCAPE:
		return
	var scene = get_tree().current_scene
	if scene == null or not scene.has_node("Player") or is_instance_valid(pause_menu):
		return
	if scene.get_node("Armory").is_open or scene.get_node("Vendors").is_open:
		return
	scene.get_node("Armory/Combat").cancel_input()
	pause_menu = load("res://menu.tscn").instantiate()
	pause_menu.in_game = true
	get_tree().root.add_child(pause_menu)
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_viewport().set_input_as_handled()

const MODE_NAMES := ["Free-for-All","Gun Game","Team Deathmatch"]
const GUN_LADDER := [[1,8],[0,5],[0,2],[0,4],[0,3],[0,0],[2,2],[2,0],[4,4],[4,0]]
func mode() -> int:
	return int(match_rules.get("mode",0))
func team(id: int) -> int:
	if mode() != 2:
		return id
	if id == 0:
		return 0
	return 0 if id-101 < int(match_rules.get("team_size",3))-1 else 1
func hostile(a: int, b: int) -> bool:
	return a != b and (mode() != 2 or team(a) != team(b))
func stage(kills: int) -> Array:
	return GUN_LADDER[clampi(kills,0,9)]