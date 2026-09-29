extends StaticBody3D
const MAX_HEALTH: int = 100
const MAX_SHIELD: int = 50
var health: int = MAX_HEALTH
var shield: int = MAX_SHIELD
var reset_remaining: float = 0
var target_number: int = 1
var readout: Label3D
var flash_remaining: float = 0

func _ready() -> void:
	readout = Label3D.new()
	readout.position = Vector3(0,1.15,0)
	readout.font_size = 34
	readout.pixel_size = 0.007
	readout.outline_size = 8
	readout.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(readout)
	_update_readout()

func take_damage(amount: int) -> Dictionary:
	if health <= 0 or amount <= 0:
		return {}
	var absorbed: int = mini(shield, amount)
	var hurt: int = mini(health, amount - absorbed)
	shield -= absorbed
	health -= hurt
	var broken: bool = absorbed > 0 and shield == 0
	if health == 0:
		reset_remaining = 3.0
	flash_remaining = 0.16
	_update_readout()
	return {"total": absorbed + hurt, "shield": absorbed, "health": hurt, "broken": broken, "eliminated": health == 0, "target": target_number}

func _process(delta: float) -> void:
	flash_remaining = maxf(0, flash_remaining - delta)
	if reset_remaining > 0:
		reset_remaining = maxf(0, reset_remaining - delta)
		if reset_remaining == 0:
			reset_target()
		else:
			_update_readout()
	if has_node("Plate"):
		var color := Color("46505b") if health == 0 else (Color("55b4dc") if shield > 0 else Color("d7664f"))
		get_node("Plate").material_override.albedo_color = Color("fff3a4") if flash_remaining > 0 else color

func reset_target() -> void:
	health = MAX_HEALTH
	shield = MAX_SHIELD
	reset_remaining = 0
	flash_remaining = 0
	_update_readout()

func _update_readout() -> void:
	if not is_instance_valid(readout):
		return
	if health <= 0:
		readout.text = "TARGET %d / ELIMINATED\nRESET %.1fs" % [target_number, reset_remaining]
		readout.modulate = Color("ffb276")
	else:
		readout.text = "TARGET %d\nSHIELD %d / 50\nHP %d / 100" % [target_number, shield, health]
		readout.modulate = Color("b9e9ff") if shield > 0 else Color("ffe4c1")


func is_headshot(point: Vector3) -> bool:
	return to_local(point).y >= 0.4
