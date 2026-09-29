extends RefCounted
const DELAY := 5.0
const HEALTH_PER_SECOND := 10.0
const SHIELD_PER_SECOND := 15.0
var elapsed := 0.0
var health_fraction := 0.0
var shield_fraction := 0.0

func reset() -> void:
	elapsed = 0.0
	health_fraction = 0.0
	shield_fraction = 0.0

func advance(target: Object, delta: float) -> void:
	if target.health <= 0:
		return
	var before := elapsed
	elapsed += delta
	var active: float = maxf(0,elapsed-DELAY)-maxf(0,before-DELAY)
	if active <= 0:
		return
	if target.health < 100:
		health_fraction += active * HEALTH_PER_SECOND
		var gain := int(health_fraction)
		target.health = mini(100,target.health+gain)
		health_fraction -= gain
	else:
		health_fraction = 0
	if target.shield < 50:
		shield_fraction += active * SHIELD_PER_SECOND
		var gain := int(shield_fraction)
		target.shield = mini(50,target.shield+gain)
		shield_fraction -= gain
	else:
		shield_fraction = 0
