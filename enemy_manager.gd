extends Node
var grid := AStarGrid2D.new()
var cells: Array[Vector2i] = []
var bots: Array = []
var player: CharacterBody3D
var grace: float = 5.0

func _ready() -> void:
	player = get_parent().get_node("Player")
	await get_tree().physics_frame
	await get_tree().physics_frame
	grid.region = Rect2i(-14,-15,29,31)
	grid.cell_size = Vector2(2,2)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.update()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.0,1.35,1.0)
	for x in range(-14,15):
		for z in range(-15,16):
			var cell := Vector2i(x,z)
			var query := PhysicsShapeQueryParameters3D.new()
			query.shape = shape
			query.transform.origin = Vector3(x*2,1.15,z*2)
			query.exclude = [player.get_rid()]
			var solid: bool = not player.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()
			grid.set_point_solid(cell,solid)
			if not solid:
				cells.append(cell)
	var rules = get_node("/root/GameSettings")
	var count: int = int(rules.match_rules.get("team_size",3))*2-1 if rules.mode() == 2 else clampi(rules.match_rules.bots,0,5)
	for i in range(count):
		var bot := CharacterBody3D.new()
		bot.set_script(preload("res://enemy.gd"))
		bot.manager = self
		bot.spawn_point = SPAWNS[i]
		bot.target_number = 101 + bots.size()
		get_parent().add_child(bot)
		bots.append(bot)
		get_parent().get_node("Scoreboard").register(bot.target_number,"Raider %d" % (bot.target_number-100))

func _process(delta: float) -> void:
	grace = maxf(0,grace-delta)

func world(cell: Vector2i) -> Vector3:
	return Vector3(cell.x*2,1.05,cell.y*2)

func nearest(point: Vector3) -> Vector2i:
	var best := Vector2i.ZERO
	var distance := INF
	for cell in cells:
		var d: float = Vector2(point.x-cell.x*2,point.z-cell.y*2).length_squared()
		if d < distance:
			best = cell
			distance = d
	return best

func path(from: Vector3, to: Vector3) -> Array[Vector3]:
	var result: Array[Vector3] = []
	for cell in grid.get_id_path(nearest(from),nearest(to),true):
		result.append(world(cell))
	return result

# Deliberate outdoor spawn pads, away from doors, stairs, vehicles and vendors.
const SPAWNS := [Vector3(-24,1.05,-24),Vector3(24,1.05,-24),Vector3(-24,1.05,24),Vector3(24,1.05,24),Vector3(-26,1.05,0),Vector3(26,1.05,0),Vector3(-16,1.05,-28),Vector3(16,1.05,28),Vector3(0,1.05,-28),Vector3(0,1.05,28),Vector3(-24,1.05,10),Vector3(24,1.05,-10)]

func pick_spawn(actor: Node3D) -> Vector3:
	var candidates: Array = SPAWNS.duplicate()
	candidates.shuffle()
	var best: Vector3 = candidates[0]
	var best_clearance := -1.0
	for point in candidates:
		var query := PhysicsShapeQueryParameters3D.new()
		var shape := CapsuleShape3D.new()
		shape.radius = 0.38
		shape.height = 1.8
		query.shape = shape
		query.transform.origin = point
		query.exclude = [actor.get_rid()]
		if not player.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty():
			continue
		var clearance := 1000.0
		for other in [player] + bots:
			if other == actor or (other != player and other.health <= 0):
				continue
			clearance = minf(clearance,point.distance_to(other.global_position))
		if clearance >= 9 and point.distance_to(actor.global_position) > 3:
			return point
		if clearance > best_clearance:
			best = point
			best_clearance = clearance
	return best
func opponent(actor: Node3D) -> Node3D:
	var settings = get_node("/root/GameSettings")
	var best: Node3D
	var best_score := INF
	for candidate in [player]+bots:
		var id: int = 0 if candidate == player else candidate.target_number
		if not settings.hostile(actor.target_number,id):
			continue
		if (candidate == player and player.get_meta("dead",false)) or (candidate != player and candidate.health <= 0):
			continue
		var distance: float = actor.global_position.distance_to(candidate.global_position)
		var score: float = distance + (0 if actor.can_see(candidate) else 40)
		if score < best_score:
			best_score = score
			best = candidate
	return best

func promote(id: int) -> void:
	var settings = get_node("/root/GameSettings")
	if settings.mode() != 1:
		return
	var score = get_parent().get_node("Scoreboard")
	var kills: int = score.stats[id].kills if score.stats.has(id) else 0
	var item: Array = settings.stage(kills)
	if id == 0:
		var armory = get_parent().get_node("Armory")
		armory.loadout = [item.duplicate(),item.duplicate()]
		armory.active_slot = 0
		armory.equip(item[0],item[1])
		armory.get_node("Combat").reset_ammo()
	else:
		for bot in bots:
			if bot.target_number == id:
				bot.category = item[0]
				bot.weapon_index = item[1]
				bot.using_sidearm = false
				bot.refresh_gun()
				bot.loaded = 20
				bot.reload_time = 0