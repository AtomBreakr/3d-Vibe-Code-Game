extends CanvasLayer
var phase := "loading"
var remaining := 0.0
var round_number := 0
var banner: Label
var result := ""
var duration := 300.0
var kill_limit := 10

func _ready() -> void:
	var rules = get_node("/root/GameSettings").match_rules
	duration = clampi(rules.minutes,1,30)*60.0
	kill_limit = 10 if get_node("/root/GameSettings").mode() == 1 else clampi(rules.kills,1,100)
	layer = 45
	banner = Label.new()
	add_child(banner)
	banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	banner.offset_left = -320
	banner.offset_right = 320
	banner.offset_top = 82
	banner.offset_bottom = 144
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_theme_font_size_override("font_size",22)
	banner.add_theme_color_override("font_outline_color",Color("14212a"))
	banner.add_theme_constant_override("outline_size",6)
	get_parent().set_meta("round_active",false)
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	prepare()

func prepare() -> void:
	phase = "prepare"
	remaining = 5 if get_node("/root/GameSettings").mode() == 1 else 30
	round_number += 1
	get_parent().set_meta("round_active",false)
	var scene = get_parent()
	var score = scene.get_node("Scoreboard")
	for id in score.stats:
		score.stats[id].kills = 0
		score.stats[id].deaths = 0
	score._refresh()
	score.close_results()
	var explosives = scene.get_node("Explosives")
	explosives.stow()
	for item in explosives.placed:
		item.node.queue_free()
	explosives.placed.clear()
	var combat = scene.get_node("Armory/Combat")
	for rocket in combat.rockets:
		rocket.node.queue_free()
	combat.rockets.clear()
	if scene.get_node("Vendors").is_open:
		scene.get_node("Vendors").close_shop()
	scene.get_node("Vitals").respawn()
	for bot in scene.get_node("Enemies").bots:
		bot.dead_time = 0
		bot.reset_bot()
	if get_node("/root/GameSettings").mode() == 1:
		scene.get_node("Enemies").promote(0)
	else:
		scene.get_node("Armory").set_open(true)
	_refresh()

func start_round() -> void:
	phase = "active"
	remaining = duration
	var scene = get_parent()
	if scene.get_node("Vendors").is_open:
		scene.get_node("Vendors").close_shop()
	scene.get_node("Armory").set_open(false)
	scene.get_node("Vitals").respawn(false)
	scene.get_node("Enemies").grace = 2
	scene.set_meta("round_active",true)
	_refresh()

func check_score() -> void:
	if phase != "active":
		return
	var score = get_parent().get_node("Scoreboard")
	if get_node("/root/GameSettings").mode() == 2:
		if score.team_kills(0) >= kill_limit or score.team_kills(1) >= kill_limit:
			finish()
		return
	for entry in score.stats.values():
		if entry.kills >= kill_limit:
			finish()
			return

func finish() -> void:
	if phase != "active":
		return
	phase = "results"
	remaining = 12
	get_parent().set_meta("round_active",false)
	get_parent().get_node("Armory/Combat").cancel_input()
	var best := -1
	var winners: Array[String] = []
	for entry in get_parent().get_node("Scoreboard").stats.values():
		if entry.kills > best:
			best = entry.kills
			winners = [entry.name]
		elif entry.kills == best:
			winners.append(entry.name)
	result = (("You win!" if winners[0] == "You" else winners[0]+" wins!") if winners.size() == 1 else "Round tied") + " / %d kills" % best
	if get_node("/root/GameSettings").mode() == 2:
		var score = get_parent().get_node("Scoreboard")
		var blue: int = score.team_kills(0)
		var red: int = score.team_kills(1)
		result = ("Team tie" if blue == red else ("Blue team wins!" if blue > red else "Red team wins!")) + " / %d - %d" % [blue,red]
	get_parent().get_node("Scoreboard").show_results(result,round_number)
	_refresh()

func _process(delta: float) -> void:
	if phase == "loading":
		return
	remaining = maxf(0,remaining-delta)
	if remaining == 0:
		if phase == "prepare":
			start_round()
		elif phase == "active":
			finish()
		else:
			prepare()
	_refresh()

func _refresh() -> void:
	var seconds := ceili(remaining)
	banner.visible = phase != "results"
	if phase == "results":
		get_parent().get_node("Scoreboard").results_countdown(seconds)
	var choosing: bool = get_parent().get_node("Armory").is_open
	banner.offset_top = 16 if choosing else 82
	banner.offset_bottom = 76 if choosing else 144
	if phase == "prepare":
		banner.text = "ROUND %d / %s\nStarts in %ds" % [round_number,"GUN GAME" if get_node("/root/GameSettings").mode() == 1 else "LOADOUT",seconds]
	elif phase == "active":
		banner.text = "%s / %02d:%02d / FIRST TO %d" % [get_node("/root/GameSettings").MODE_NAMES[get_node("/root/GameSettings").mode()].to_upper(),seconds/60,seconds%60,kill_limit]
	else:
		banner.text = result + "\nNext loadout phase in %ds" % seconds
