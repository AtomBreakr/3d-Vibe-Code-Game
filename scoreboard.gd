extends CanvasLayer
var stats: Dictionary = {}
var overlay: ColorRect
var rows: GridContainer
var summary: Label
var title: Label
var help: Label
var showing_results := false

func _ready() -> void:
	layer = 50
	overlay = ColorRect.new()
	add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.025,0.04,0.065,0.94)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var center := CenterContainer.new()
	overlay.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",20)
	center.add_child(column)
	title = Label.new()
	title.text = get_node("/root/GameSettings").MODE_NAMES[get_node("/root/GameSettings").mode()].to_upper() + " / SCOREBOARD"
	title.add_theme_font_size_override("font_size",28)
	column.add_child(title)
	summary = Label.new()
	column.add_child(summary)
	rows = GridContainer.new()
	rows.columns = 5
	rows.add_theme_constant_override("h_separation",35)
	rows.add_theme_constant_override("v_separation",14)
	column.add_child(rows)
	help = Label.new()
	help.text = "Hold Tab to view / Release to return\nK/D = kills divided by deaths (uses 1 until your first death).\nSelf-eliminations count as deaths only. Stats reset each round."
	help.add_theme_font_size_override("font_size",15)
	column.add_child(help)
	register(0,"You")
	overlay.hide()

func register(id: int, display_name: String) -> void:
	if stats.has(id):
		return
	stats[id] = {"name":display_name,"kills":0,"deaths":0}
	_refresh()

func record_death(victim: int, attacker: int) -> void:
	if not get_parent().get_meta("round_active",true):
		return
	if not stats.has(victim):
		return
	stats[victim].deaths += 1
	if get_node("/root/GameSettings").hostile(attacker,victim) and stats.has(attacker):
		stats[attacker].kills += 1
		if attacker == 0:
			get_parent().get_node("Vendors").award_kill()
		if get_node("/root/GameSettings").mode() == 1:
			get_parent().get_node("Enemies").call_deferred("promote",attacker)
	_refresh()
	if get_parent().has_node("Rounds"):
		get_parent().get_node("Rounds").check_score()

func ratio(id: int) -> float:
	return float(stats[id].kills) / maxi(1,stats[id].deaths)

func _input(event: InputEvent) -> void:
	if showing_results:
		return
	if event is InputEventKey and event.is_action("scoreboard"):
		overlay.visible = event.pressed
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(overlay) and not showing_results:
		overlay.hide()

func _refresh() -> void:
	for child in rows.get_children():
		rows.remove_child(child)
		child.queue_free()
	var settings = get_node("/root/GameSettings")
	summary.text = "BLUE %d  /  RED %d" % [team_kills(0),team_kills(1)] if settings.mode() == 2 else ("10 kills to win / Upgrade on each kill" if settings.mode() == 1 else "Every player for themselves")
	for heading in ["PLAYER / NPC","KILLS","DEATHS","K/D","TEAM" if settings.mode() == 2 else ("WEAPON TIER" if settings.mode() == 1 else "")]:
		_cell(heading,Color("a8bacb"))
	for id in stats:
		var entry: Dictionary = stats[id]
		var color := Color("8edbff") if id == 0 else Color("edf1f5")
		if settings.mode() == 2:
			color = Color("8edbff") if settings.team(id) == 0 else Color("ff9988")
		var extra: String = ("BLUE" if settings.team(id) == 0 else "RED") if settings.mode() == 2 else ("%d / 10" % mini(entry.kills+1,10) if settings.mode() == 1 else "--")
		for text in [entry.name,str(entry.kills),str(entry.deaths),"%.2f" % ratio(id),extra]:
			_cell(text,color)

func _cell(text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size.x = 80
	label.add_theme_font_size_override("font_size",20)
	label.add_theme_color_override("font_color",color)
	rows.add_child(label)

func team_kills(team_id: int) -> int:
	var total := 0
	for id in stats:
		if get_node("/root/GameSettings").team(id) == team_id:
			total += stats[id].kills
	return total
func show_results(winner: String, number: int) -> void:
	showing_results = true
	title.text = "ROUND %d COMPLETE\n%s" % [number,winner]
	title.add_theme_color_override("font_color",Color("f3c675"))
	_refresh()
	overlay.show()

func results_countdown(seconds: int) -> void:
	help.text = "Next round begins in %ds\nKills / Deaths / K/D / Final round standings" % seconds

func close_results() -> void:
	showing_results = false
	overlay.hide()
	title.text = get_node("/root/GameSettings").MODE_NAMES[get_node("/root/GameSettings").mode()].to_upper() + " / SCOREBOARD"
	title.add_theme_color_override("font_color",Color.WHITE)
	help.text = "Hold Tab to view / Release to return\nK/D = kills divided by deaths (uses 1 until your first death).\nSelf-eliminations count as deaths only. Stats reset each round."